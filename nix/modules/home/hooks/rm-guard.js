// PreToolUse(Bash) hook: auto-approve `rm` only when every target is "safe":
//   - under a temp dir (/tmp, /private/tmp, $TMPDIR, and the session scratchpad
//     which lives under /private/tmp)
//   - under <gitRoot>/tmp (project tmp/ subdir)
//   - a git-tracked path in the current repo (recoverable via `git restore`)
// Anything else (or any uncertainty) -> stay silent and let the normal
// `ask rm:*` permission rule prompt. This hook never denies.
"use strict";

const fs = require("fs");
const os = require("os");
const path = require("path");
const { execFileSync } = require("child_process");

// Emit nothing and exit cleanly -> falls through to normal permission flow.
function passThrough() {
  process.exit(0);
}

function allow(reason) {
  process.stdout.write(
    JSON.stringify({
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "allow",
        permissionDecisionReason: reason,
      },
    })
  );
  process.exit(0);
}

// Split a command line into tokens, honoring single/double quotes and
// backslash escapes well enough for path operands.
function tokenize(cmd) {
  const tokens = [];
  let cur = "";
  let inTok = false;
  let i = 0;
  while (i < cmd.length) {
    const c = cmd[i];
    if (c === " " || c === "\t") {
      if (inTok) {
        tokens.push(cur);
        cur = "";
        inTok = false;
      }
      i++;
      continue;
    }
    inTok = true;
    if (c === '"' || c === "'") {
      const q = c;
      i++;
      while (i < cmd.length && cmd[i] !== q) {
        if (q === '"' && cmd[i] === "\\" && i + 1 < cmd.length) {
          cur += cmd[i + 1];
          i += 2;
        } else {
          cur += cmd[i];
          i++;
        }
      }
      i++; // closing quote
      continue;
    }
    if (c === "\\" && i + 1 < cmd.length) {
      cur += cmd[i + 1];
      i += 2;
      continue;
    }
    cur += c;
    i++;
  }
  if (inTok) tokens.push(cur);
  return tokens;
}

function real(p) {
  try {
    return fs.realpathSync(p);
  } catch (_e) {
    return p;
  }
}

function isStrictlyUnder(abs, root) {
  if (!root) return false;
  return abs.startsWith(root + path.sep);
}

function main() {
  let raw = "";
  try {
    raw = fs.readFileSync(0, "utf8");
  } catch (_e) {
    passThrough();
  }

  let data;
  try {
    data = JSON.parse(raw);
  } catch (_e) {
    passThrough();
  }

  const command = (data.tool_input && data.tool_input.command) || "";
  const cwd = data.cwd || process.cwd();
  if (!command) passThrough();

  // Only handle a single, simple `rm` invocation. Bail on any shell control
  // operators, redirects, substitutions, variables, or newlines so we never
  // approve more than the rm we inspected.
  if (/[;&|<>$\n`]/.test(command)) passThrough();

  const tokens = tokenize(command);
  if (!tokens.length) passThrough();
  if (tokens[0] !== "rm" && tokens[0] !== "/bin/rm") passThrough();

  // Separate flags from path operands (`--` ends flag parsing).
  const operands = [];
  let noMoreFlags = false;
  for (let k = 1; k < tokens.length; k++) {
    const t = tokens[k];
    if (!noMoreFlags && t === "--") {
      noMoreFlags = true;
      continue;
    }
    if (!noMoreFlags && t.startsWith("-")) continue;
    operands.push(t);
  }
  if (!operands.length) passThrough();

  // Safe temp roots (raw + realpath'd, since /tmp -> /private/tmp on macOS).
  const tmpRoots = ["/tmp", "/private/tmp"];
  if (process.env.TMPDIR) tmpRoots.push(process.env.TMPDIR.replace(/\/$/, ""));
  const safeRoots = new Set();
  for (const r of tmpRoots) {
    safeRoots.add(r);
    safeRoots.add(real(r));
  }

  // Current repo root and its tmp/ subdir.
  let repoRoot = null;
  try {
    repoRoot = execFileSync("git", ["-C", cwd, "rev-parse", "--show-toplevel"], {
      encoding: "utf8",
      stdio: ["ignore", "pipe", "ignore"],
    }).trim();
  } catch (_e) {
    repoRoot = null;
  }
  if (repoRoot) {
    const projTmp = path.join(repoRoot, "tmp");
    safeRoots.add(projTmp);
    safeRoots.add(real(projTmp));
  }
  const roots = Array.from(safeRoots).filter(Boolean);

  function expandHome(p) {
    if (p === "~") return os.homedir();
    if (p.startsWith("~/")) return path.join(os.homedir(), p.slice(2));
    return p;
  }

  function underTemp(abs) {
    const r = real(abs);
    return roots.some((root) => isStrictlyUnder(abs, root) || isStrictlyUnder(r, root));
  }

  // A target inside the repo is safe iff it is fully git-tracked (recoverable).
  // Never approve deleting the repo root itself (would nuke .git history).
  function gitTrackedSafe(abs) {
    if (!repoRoot) return false;
    if (abs === repoRoot) return false;
    if (!isStrictlyUnder(abs, repoRoot)) return false;
    const rel = path.relative(repoRoot, abs);

    let stat = null;
    try {
      stat = fs.lstatSync(abs);
    } catch (_e) {
      stat = null;
    }

    if (stat && stat.isDirectory()) {
      let tracked = "";
      let others = "";
      try {
        tracked = execFileSync("git", ["-C", repoRoot, "ls-files", "--", rel], {
          encoding: "utf8",
        }).trim();
        // No --exclude-standard: counts ignored files too, since `rm -rf` would
        // delete those and they are not recoverable from git.
        others = execFileSync("git", ["-C", repoRoot, "ls-files", "--others", "--", rel], {
          encoding: "utf8",
        }).trim();
      } catch (_e) {
        return false;
      }
      return tracked !== "" && others === "";
    }

    // File (or already-deleted path still in the index).
    try {
      execFileSync("git", ["-C", repoRoot, "ls-files", "--error-unmatch", "--", rel], {
        stdio: "ignore",
      });
      return true;
    } catch (_e) {
      return false;
    }
  }

  const globRe = /[*?[]/;

  const allSafe = operands.every((op) => {
    const expanded = expandHome(op);

    if (globRe.test(expanded)) {
      // Can't resolve globs (shell hasn't expanded them in the hook input).
      // Only accept if the literal base dir before the glob is under a temp root.
      const base = expanded.replace(/\/[^/]*[*?[].*$/, "");
      if (!base || base === expanded) return false;
      return underTemp(path.resolve(cwd, base));
    }

    const abs = path.resolve(cwd, expanded);
    if (abs === "/" || abs === path.dirname(abs) && abs.length <= 1) return false;
    if (underTemp(abs)) return true;
    if (gitTrackedSafe(abs)) return true;
    return false;
  });

  if (allSafe) {
    allow("rm targets are temp files, project tmp/, or git-tracked (recoverable) paths");
  }
  passThrough();
}

try {
  main();
} catch (_e) {
  // Never block on an internal error; fall through to normal permissions.
  process.exit(0);
}

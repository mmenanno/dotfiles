{ inputs, lib, homeDirectory, ... }:

let
  gsd = inputs.get-shit-done;
  hooksDir = "${homeDirectory}/.claude/hooks";
in {
  home.file = {
    # Slash commands (e.g., /gsd:new-project, /gsd:quick, etc.)
    ".claude/commands/gsd".source = "${gsd}/commands/gsd";

    # Agents (individual files to coexist with other agents in ~/.claude/agents/)
    ".claude/agents/gsd-codebase-mapper.md".source = "${gsd}/agents/gsd-codebase-mapper.md";
    ".claude/agents/gsd-debugger.md".source = "${gsd}/agents/gsd-debugger.md";
    ".claude/agents/gsd-executor.md".source = "${gsd}/agents/gsd-executor.md";
    ".claude/agents/gsd-integration-checker.md".source = "${gsd}/agents/gsd-integration-checker.md";
    ".claude/agents/gsd-phase-researcher.md".source = "${gsd}/agents/gsd-phase-researcher.md";
    ".claude/agents/gsd-plan-checker.md".source = "${gsd}/agents/gsd-plan-checker.md";
    ".claude/agents/gsd-planner.md".source = "${gsd}/agents/gsd-planner.md";
    ".claude/agents/gsd-project-researcher.md".source = "${gsd}/agents/gsd-project-researcher.md";
    ".claude/agents/gsd-research-synthesizer.md".source = "${gsd}/agents/gsd-research-synthesizer.md";
    ".claude/agents/gsd-roadmapper.md".source = "${gsd}/agents/gsd-roadmapper.md";
    ".claude/agents/gsd-verifier.md".source = "${gsd}/agents/gsd-verifier.md";

    # Core GSD system (workflows, templates, references, bin)
    ".claude/get-shit-done".source = "${gsd}/get-shit-done";

    # Hook scripts (source files work as-is for Claude Code - no external deps)
    ".claude/hooks/gsd-context-monitor.js".source = "${gsd}/hooks/gsd-context-monitor.js";
    ".claude/hooks/gsd-check-update.js".source = "${gsd}/hooks/gsd-check-update.js";
    ".claude/hooks/gsd-statusline.js".source = "${gsd}/hooks/gsd-statusline.js";

    # Combined statusline: GSD metrics + Starship prompt
    ".claude/hooks/combined-statusline.sh" = {
      executable = true;
      text = ''
        #!/bin/bash
        input=$(cat)
        gsd=$(echo "$input" | node "${hooksDir}/gsd-statusline.js" 2>/dev/null || true)
        star=$(STARSHIP_SHELL=fish STARSHIP_CONFIG="$HOME/.config/starship.toml" starship prompt 2>/dev/null | head -1 || true)
        printf '%s %s' "$gsd" "$star"
      '';
    };

    # CommonJS mode marker for hooks (prevents "require is not defined" errors)
    ".claude/package.json".text = ''{"type":"commonjs"}'';
  };

  programs.claude-code.settings = {
    # Override statusline with combined GSD + Starship
    statusLine = lib.mkForce {
      type = "command";
      command = "${hooksDir}/combined-statusline.sh";
    };

    hooks = {
      # Update check on session start (reports via /gsd:update; Nix updates via nix flake update)
      SessionStart = [{
        hooks = [{
          type = "command";
          command = "node \"${hooksDir}/gsd-check-update.js\"";
        }];
      }];
      # Context window monitor - warns agent when context is running low
      PostToolUse = [{
        hooks = [{
          type = "command";
          command = "node \"${hooksDir}/gsd-context-monitor.js\"";
        }];
      }];
    };
  };
}

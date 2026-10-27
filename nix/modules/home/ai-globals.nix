_:

# Global Claude Code instructions (~/.claude/CLAUDE.md). Codex and Gemini read
# their global files from ~/.codex and ~/.gemini; see codex.nix's `context`.

let
  editor = "VS Code";
  gitCommand = "code --wait";
in
{
  home.file = {
    # Global Claude configuration in ~/.claude/CLAUDE.md
    # Supported by: Claude Code
    ".claude/CLAUDE.md".text = ''
      # Global Claude Code Defaults

      Project-specific CLAUDE.md files override these settings.

      ## Editor

      - Primary: ${editor}
      - Git editor: `${gitCommand}`

      ## CLI Tool Preferences

      Use these instead of traditional commands:

      | Instead of | Use | Why |
      |------------|-----|-----|
      | `cat` | `bat` | Syntax highlighting, line numbers |
      | `ls` | `eza` | Git integration, better formatting |
      | `grep` | `rg` | Faster, respects .gitignore |
      | `find` | `fd` | Simpler syntax, faster |

      Other available tools:
      - `atuin` - Shell history search (Ctrl+R)
      - `direnv` - Auto-loads `.envrc` files
      - `delta` - Git pager with syntax highlighting (auto-used by git diff/log)
      - `mise` - Development tool version manager (replaces asdf/nvm/rbenv)

      ## MCP Tool Preferences

      When an MCP tool exists for an operation, prefer it over the CLI equivalent. MCP tools provide structured output, better error handling, and avoid shell quoting issues.

      ### GitHub: MCP plugin over `gh` CLI

      Use the GitHub MCP plugin (`mcp__plugin_github_github__*`) for most GitHub operations: reading PRs/commits, creating branches, searching code, etc. Fall back to `gh` CLI when the MCP plugin lacks the needed capability (e.g., `gh run` for workflow runs, `gh pr checkout` for local checkout).

      A few MCP tools are deliberately denied — use the `gh` CLI instead:

      - Reading issues (`issue_read`) → `gh issue view` / `gh issue list`
      - Reading file contents (`get_file_contents`) → `gh api`
      - Writing sub-issues (`sub_issue_write`) → `gh api`

      ### Browser: Playwright MCP vs Claude In Chrome

      - **Playwright MCP** (`mcp__plugin_playwright_playwright__*`): Use for testing application features — dev servers, staging environments, localhost. Opens its own browser session.
      - **Claude In Chrome**: Use when you need an authenticated user session that already exists in the user's browser — work apps (Jira, Slack), personal accounts (Gmail, GitHub UI, banking), or any site requiring existing cookies/login.

      ### Notion: MCP plugin over web

      Use the Notion MCP plugin (`mcp__claude_ai_Notion__*`) for searching, reading, creating, and updating Notion pages. Do not scrape Notion via browser.

      ## 1Password CLI

      Shell aliases don't inherit into non-interactive subshells. For 1Password-plugin-backed tools whose alias exists only in zsh, wrap with `op plugin run --`. Exception: `gh` is logged in with its own stored credential in the macOS Keychain (see `gh.nix`) and works directly in any context — no `op plugin run --` needed.

      ## Git

      - Favour rebasing over merge commits to keep history linear. Use `git rebase` (or `git pull --rebase`) instead of `git merge`; avoid creating merge commits.

      ## Shell Commands

      - Never prepend `cd <dir> &&` to commands when already in the correct working directory. Only use `cd` when the command must run in a different directory than the current one.

      ## Shell Scripts

      Always include:
      ```bash
      #!/usr/bin/env bash
      set -euo pipefail
      ```
    '';
  };
}

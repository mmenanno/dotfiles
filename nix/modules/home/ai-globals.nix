_:

# Global AI agent configuration files for all AI coding assistants
# This module manages vendor-neutral global defaults that apply across all projects
# unless overridden by project-specific configuration files.

let
  # Common validation commands across different project types
  validationCommands = {
    nix = "nix flake check";
    shell = "shellcheck *.sh bin/*";
    markdown = "markdownlint *.md";
    nodejs = [ "npm run lint" "npm run test" ];
    ruby = [ "bundle exec rubocop" "bundle exec rspec" ];
    python = [ "pylint *.py" "pytest" ];
  };

  # Common security constraints for all AI agents
  prohibitedOperations = [
    "Executing destructive file operations (`rm -rf`, etc.)"
    "Running commands with `sudo` privileges"
    "Modifying database schemas or data without explicit approval"
    "Making external API calls to unknown endpoints"
    "Accessing or modifying sensitive files (.env, secrets, etc.)"
  ];

  allowedOperations = [
    "Linting and formatting commands"
    "Test suites and validation scripts"
    "Build and compilation commands (dry-run)"
    "File reading operations"
    "Git status and diff operations"
  ];

  # Common behavioral preferences
  commonBehaviors = {
    codeStyle = [
      "Use consistent indentation (2 spaces for YAML/Nix, 4 for Python, project-specific for others)"
      "Write descriptive variable and function names"
      "Include comprehensive error handling"
      "Add comments for complex logic"
      "Follow language-specific conventions"
    ];

    workflow = [
      "Test-driven development when appropriate"
      "Small, focused commits with clear messages"
      "Documentation for complex features"
      "Performance considerations for production code"
      "Security-first approach to all changes"
    ];

    shellScripting = [
      "Use #!/bin/bash shebang"
      "Include 'set -euo pipefail' for safety"
      "Must pass shellcheck validation"
      "**1Password Plugin Pattern**: For CLI tools with 1Password plugin support in non-interactive subshells where the shell alias isn't visible, wrap commands with 'op plugin run --'. Not needed for 'gh': its token is persisted at ~/.config/gh/hosts.yml by gh.nix, so 'gh' works directly from any context."
    ];
  };

  # Helper function to format command lists
  formatCommandList = commands:
    if builtins.isList commands
    then builtins.concatStringsSep "\n      " commands
    else commands;

  # Helper function to format bullet points
  formatBulletList = items: builtins.concatStringsSep "\n      - " ([""] ++ items);

  # Common editor and tool preferences
  commonToolPreferences = {
    editor = "VS Code";
    gitCommand = "code --wait";
    shell = "zsh with modern plugin management";
    terminalFont = "MesloLGS Nerd Font";
    modernCliTools = [
      "bat - cat with syntax highlighting (use instead of cat for viewing files)"
      "eza - modern ls with git integration (use instead of ls)"
      "ripgrep (rg) - fast grep alternative (use for searching code)"
      "fd - fast find alternative (use for finding files)"
      "atuin - magical shell history with sync (Ctrl+R for search)"
      "direnv - automatic environment activation for .envrc files"
    ];
  };

  # Common integration notes template
  integrationTemplate = toolName: ''
    ## Integration with Project-Specific Configuration

    This global configuration provides baseline behavioral preferences. Project-specific ${toolName} files should:

    - Reference this global configuration as the foundation
    - Override specific behaviors as needed for the project
    - Maintain consistency with security constraints from AGENTS.md
    - Document any deviations from global defaults
  '';

in
{
  home.file = {
    # Global AGENTS.md - Vendor-neutral execution playbook
    # Supported by: Codex, and other AI tools following the AGENTS.md standard
    "AGENTS.md".text = ''
      # Global AI Agent Configuration

      This file serves as the global default configuration for all AI programming assistants. Project-specific AGENTS.md files will override these settings.

      ## Universal Execution Constraints

      ### Mandatory Validation Commands

      Before any code changes are submitted, AI agents MUST execute appropriate validation commands:

      ```bash
      # For Nix projects
      ${validationCommands.nix}

      # For shell scripts
      ${validationCommands.shell}

      # For markdown files
      ${validationCommands.markdown}

      # For Node.js projects
      ${formatCommandList validationCommands.nodejs}

      # For Ruby projects
      ${formatCommandList validationCommands.ruby}

      # For Python projects
      ${formatCommandList validationCommands.python}
      ```

      ### Universal Code Style Guidelines
      ${formatBulletList commonBehaviors.codeStyle}

      ### Shell Scripting Guidelines
      ${formatBulletList commonBehaviors.shellScripting}

      ### Security Requirements

      AI agents are PROHIBITED from:
      ${formatBulletList prohibitedOperations}

      AI agents MAY execute:
      ${formatBulletList allowedOperations}

      ### Development Workflow Preferences
      ${formatBulletList commonBehaviors.workflow}

      ## Integration Notes

      This global configuration provides baseline constraints that apply across all projects. Individual repositories may have additional requirements specified in their project-specific AGENTS.md files.

      For detailed behavioral preferences, refer to tool-specific configuration files (CLAUDE.md, GEMINI.md, etc.).
    '';

    # Global Claude configuration in ~/.claude/CLAUDE.md
    # Supported by: Claude Code
    ".claude/CLAUDE.md".text = ''
      # Global Claude Code Defaults

      Project-specific CLAUDE.md files override these settings.

      ## Editor

      - Primary: ${commonToolPreferences.editor}
      - Git editor: `${commonToolPreferences.gitCommand}`

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

      Use the GitHub MCP plugin (`mcp__plugin_github_github__*`) for all GitHub operations: reading issues/PRs/commits, creating branches, searching code, etc. Fall back to `gh` CLI only when the MCP plugin lacks the needed capability (e.g., `gh run` for workflow runs, `gh api` for arbitrary API calls, `gh pr checkout` for local checkout).

      ### Browser: Playwright MCP vs Claude In Chrome

      - **Playwright MCP** (`mcp__plugin_playwright_playwright__*`): Use for testing application features — dev servers, staging environments, localhost. Opens its own browser session.
      - **Claude In Chrome**: Use when you need an authenticated user session that already exists in the user's browser — work apps (Jira, Slack), personal accounts (Gmail, GitHub UI, banking), or any site requiring existing cookies/login.

      ### Notion: MCP plugin over web

      Use the Notion MCP plugin (`mcp__claude_ai_Notion__*`) for searching, reading, creating, and updating Notion pages. Do not scrape Notion via browser.

      ## 1Password CLI

      Shell aliases don't inherit into non-interactive subshells. For 1Password-plugin-backed tools whose alias exists only in zsh, wrap with `op plugin run --`. Exception: `gh` has its token persisted in `~/.config/gh/hosts.yml` (see `gh.nix`) and works directly in any context — no `op plugin run --` needed.

      ## Shell Commands

      - Never prepend `cd <dir> &&` to commands when already in the correct working directory. Only use `cd` when the command must run in a different directory than the current one.

      ## Shell Scripts

      Always include:
      ```bash
      #!/bin/bash
      set -euo pipefail
      ```
    '';

    # Global Gemini configuration in ~/GEMINI.md
    # Supported by: Gemini Code (with hierarchical loading)
    "GEMINI.md".text = ''
      # Global Gemini Code Configuration

      This file defines global default instruction memory and behavioral preferences for Gemini Code. Project-specific GEMINI.md files will override these settings.

      ## Global Memory and Context Preferences

      ### Hierarchical Loading

      - Load from current directory → project root → home directory
      - Merge configurations with project-specific settings taking precedence
      - Use `/memory show` to display current contextual combination

      ### Instruction Memory

      - Remember user preferences across sessions
      - Maintain context about common project patterns
      - Adapt responses based on successful interactions

      ## Global Behavioral Preferences

      ### Planning and Execution

      - Always present plans before execution for complex operations
      - Provide clear preview of changes before implementation
      - Request user confirmation for significant modifications

      ### Code Generation Patterns

      - Follow established patterns from successful projects
      - Prioritize maintainability and readability
      - Consider performance implications for production code

      ## Global Tool Integration Preferences

      ### Development Workflow

      - Emphasize human-in-the-loop throughout execution chain
      - Break down complex tasks into reviewable steps
      - Provide comprehensive explanations for suggested changes

      ### Available Modern CLI Tools
      ${formatBulletList commonToolPreferences.modernCliTools}

      ### Memory Management

      - Track successful solutions for common problems
      - Learn from user feedback and corrections
      - Adapt communication style to user preferences

      ## Global Security and Safety

      ### Human Oversight

      - Require explicit confirmation for potentially dangerous operations
      - Maintain principle of least privilege for all operations
      - Follow security requirements defined in AGENTS.md

      ### Plan Validation

      - Verify all plans against allowed operations list
      - Ensure compliance with project-specific constraints
      - Provide safety warnings for edge cases or risky operations

      ## Integration with Other Configuration Files

      This global configuration works with:

      - **AGENTS.md**: Provides security constraints and validation requirements
      - **Project-specific GEMINI.md**: Override global preferences as needed
      - **CLAUDE.md**: Share common behavioral preferences where applicable

      ${integrationTemplate "GEMINI.md"}
    '';

  };
}

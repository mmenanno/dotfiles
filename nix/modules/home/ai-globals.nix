{ config, pkgs, ... }:

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
      "**1Password Plugin Pattern**: When using CLI tools with 1Password plugin support (like 'gh') in non-interactive subshells, wrap commands with 'op plugin run --' to ensure proper authentication. Example: op plugin run -- gh repo view"
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
    editor = "Cursor";
    gitCommand = "cursor --wait";
    shell = "zsh with modern plugin management";
    terminalFont = "MesloLGS Nerd Font";
  };

  # Common security guidelines template
  securityGuidelines = {
    permissionBoundaries = [
      "Respect all security constraints from AGENTS.md"
      "Never bypass security restrictions without explicit approval"
      "Maintain principle of least privilege for all operations"
      "Provide clear warnings for potentially risky operations"
    ];

    dataProtection = [
      "Handle sensitive information appropriately"
      "Avoid logging or storing credentials"
      "Respect privacy boundaries and data sensitivity"
      "Follow secure coding practices consistently"
    ];

    onePasswordIntegration = [
      "Shell aliases don't work in non-interactive subshells"
      "In scripts that spawn subshells, explicitly wrap plugin-enabled commands: op plugin run -- gh <command>"
      "See: https://developer.1password.com/docs/cli/shell-plugins/troubleshooting/#if-your-script-doesnt-inherit-shell-plugin-aliases"
    ];
  };

  # Template for generating configuration sections
  generateConfigSection = { title, items, useSubheadings ? false }:
    if useSubheadings
    then ''
      ## ${title}

      ### Permission Boundaries
      ${formatBulletList securityGuidelines.permissionBoundaries}

      ### Data Protection
      ${formatBulletList securityGuidelines.dataProtection}
    ''
    else ''
      ## ${title}
      ${formatBulletList items}
    '';

  # Common integration notes template
  integrationTemplate = toolName: ''
    ## Integration with Project-Specific Configuration

    This global configuration provides baseline behavioral preferences. Project-specific ${toolName} files should:

    - Reference this global configuration as the foundation
    - Override specific behaviors as needed for the project
    - Maintain consistency with security constraints from AGENTS.md
    - Document any deviations from global defaults
  '';

  # Common validation requirements template for Cursor rules
  validationRequirementsTemplate = ''
    ## Universal Validation Requirements

    All AI agents must execute appropriate validation commands before changes:

    - `${validationCommands.nix}` for Nix projects
    - `${validationCommands.shell}` for shell scripts
    - `${validationCommands.markdown}` for markdown files
    - Language-specific linting and testing
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
      # Global Claude Code Configuration

      This file defines global default behavioral preferences for Claude Code. Project-specific CLAUDE.md files will override these settings.

      ## Global Behavioral Preferences

      ### Code Generation Style

      - Prefer object-oriented programming patterns where applicable
      - Use descriptive variable names and clear code structure
      - Minimize external dependencies when possible
      - Always include comprehensive error handling

      ### Development Workflow

      - Test-driven development when appropriate
      - Small, focused commits with clear messages
      - Documentation for complex logic and architectural decisions
      - Performance considerations for production code

      ## Universal Tool Configurations

      ### Editor Integration

      - Primary editor: ${commonToolPreferences.editor}
      - Use `${commonToolPreferences.gitCommand}` for git operations
      - Leverage editor AI features appropriately

      ### Terminal Preferences

      - Shell: ${commonToolPreferences.shell}
      - Use descriptive command aliases
      - Prefer structured output for complex commands

      ### Permission Preferences

      - Always validate operations against AGENTS.md constraints
      - Request confirmation for potentially destructive operations
      - Enable batch operations only in safe environments

      ${generateConfigSection { title = "Global Security Guidelines"; items = []; useSubheadings = true; }}

      ${integrationTemplate "CLAUDE.md"}
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

    # Global Cursor rules directory
    # Supported by: Cursor IDE (modern rules system)
    ".cursor/rules/global-ai-integration.md".text = ''
      ---
      type: always
      description: "Global AI Agent Configuration Integration"
      ---

      # Global AI Agent Configuration

      This rule integrates with global AI agent configuration files in the home directory.

      ## Global Configuration Hierarchy

      1. **~/AGENTS.md**: Universal execution constraints and security boundaries
      2. **~/.claude/CLAUDE.md**: Claude-specific global behavioral preferences
      3. **~/GEMINI.md**: Gemini-specific global instruction memory
      4. **Project-specific files**: Override global defaults as needed

      ${validationRequirementsTemplate}

      ## Security Boundaries

      Global security constraints apply to all projects:

      - No destructive file operations without approval
      - No sudo or system modification commands
      - No access to sensitive files (.env, secrets)
      - Principle of least privilege for all operations

      ### 1Password CLI Integration
      ${formatBulletList securityGuidelines.onePasswordIntegration}

      ## Integration Behavior

      - Reference global configurations as baseline
      - Allow project-specific overrides
      - Maintain consistency across all AI tools
      - Prioritize security constraints over convenience
    '';
  };
}

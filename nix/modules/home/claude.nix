{ config, pkgs, dotlib, ... }:

let
  inherit (dotlib) getEnvOrFallback;

  # GitHub MCP token with fallback pattern
  githubMcpToken = getEnvOrFallback "NIX_GITHUB_MCP_TOKEN" "bootstrap-github-token" "placeholder-github-token";

  # Define permission groups and helpers reused in settings
  devTools = [
    "npm run lint"
    "npm run test:*"
    "npm run build"
    "yarn lint"
    "cargo check"
    "cargo test"
    "pytest:*"
    "go test:*"
    "make test"
  ];
  coreRubyTools = [
    "brakeman"
    "erb_lint"
    "rake"
    "rails"
    "rspec"
    "rubocop"
    "rbs"
    "spoom"
    "srb"
    "toys"
    "tapioca"
    "yard"
  ];
  rubyTools = [
    "bundle:*"
    "bin/bundle:*"
    "ruby --version"
  ] ++ (map (tool: "bundle exec ${tool}:*") coreRubyTools)
      ++ (map (tool: "${tool}:*") coreRubyTools)
      ++ (map (tool: "bin/${tool}:*") coreRubyTools);
  gitOps = [
    "git status"
    "git diff:*"
    "git log:*"
    "git show:*"
    "git add:*"
    "git commit:*"
    "git config:*"
  ];
  safeShellCommands = [
    "ls:*"
    "ll:*"
    "la:*"
    "pwd"
    "whoami"
    "date"
    "uname:*"
    "which:*"
    "whereis:*"
    "cat:*"
    "head:*"
    "tail:*"
    "wc:*"
    "sort:*"
    "uniq:*"
    "cut:*"
    "awk:*"
    "sed:*"
    "find:*"
    "locate:*"
    "tree:*"
    "du:*"
    "df:*"
    "ps:*"
    "top"
    "htop"
    "env"
    "printenv:*"
    "echo:*"
    "printf:*"
    "basename:*"
    "dirname:*"
    "realpath:*"
    "readlink:*"
    "file:*"
    "stat:*"
    "diff:*"
    "comm:*"
    "cmp:*"
    "md5:*"
    "shasum:*"
    "curl:*"
    "wget:*"
    "ping:*"
    "nslookup:*"
    "dig:*"
    "history:*"
    "alias"
    "type:*"
    "command:*"
  ];
  safeReads = [
    "package.json"
    "Gemfile"
    "Gemfile.lock"
    "Rakefile"
    "Makefile"
    "README.md"
    "**/*.md"
    "~/.zshrc"
    "~/.gitconfig"
    "**/*.toml"
  ];
  webDomains = [
    "github.com"
    "raw.githubusercontent.com"
    "api.github.com"
    "gist.github.com"
    "starship.rs"
    "www.nerdfonts.com"
    "nix-darwin.github.io"
    "nix-community.github.io"
    "docs.anthropic.com"
  ];
  toBashPermissions = commands: map (cmd: "Bash(${cmd})") commands;
  toReadPermissions = files: map (file: "Read(${file})") files;
  toWebFetchPermissions = domains: map (domain: "WebFetch(domain:${domain})") domains;
in
{
  programs.claude-code = {
    enable = true;

    settings = {
      statusLine = {
        type = "command";
        command = "input=$(cat); cwd=$(echo \"$input\" | jq -r '.workspace.current_dir'); cd \"$cwd\" 2>/dev/null || true; STARSHIP_CONFIG=$HOME/.config/starship.toml starship prompt | sed 's/%{\\([^}]*\\)%}/\\x1b[\\1/g'";
      };
      includeCoAuthoredBy = false;
      theme = "dark";
      autoUpdates = true;
      verbose = false;
      cleanupPeriodDays = 20;
      permissions = {
        allow =
          (toBashPermissions devTools)
          ++ (toBashPermissions rubyTools)
          ++ (toBashPermissions gitOps)
          ++ (toBashPermissions safeShellCommands)
          ++ (toReadPermissions safeReads)
          ++ (toBashPermissions [
            "nix flake update:*"
            "/usr/bin/env nix flake:*"
            "nixup:*"
            "nix flake metadata:*"
            "nix flake check:*"
          ])
          ++ [ "WebSearch" ]
          ++ (toWebFetchPermissions webDomains)
          ++ [ "Bash(gh repo view:*)" ]
          ++ (toBashPermissions [
            "brew search:*"
            "defaults read:*"
            "grep:*"
            "mkdir:*"
            "mise:*"
          ]);
        ask = toBashPermissions [
          "git push:*"
          "rm:*"
          "sudo:*"
          "chmod:*"
        ];
        deny = [];
        additionalDirectories = [];
        defaultMode = "acceptEdits";
      };
    };

    mcpServers = {
      github = {
        command = "github-mcp-server";
        args = [ "stdio" ];
        env = { GITHUB_PERSONAL_ACCESS_TOKEN = githubMcpToken; };
      };
      rails = {
        command = "rails-mcp-server";
        args = [ "stdio" ];
        env = { };
      };
    };
  };

  # User-specific Claude configuration (persisted file under $HOME)
  home.file."CLAUDE.md".text = ''
    # User Configuration

    ## Personal Preferences
    - Prefer object-oriented programming patterns where applicable
    - Use descriptive variable names and clear code structure
    - Minimize external dependencies when possible

    ## Development Environment
    - Primary editor: Cursor
    - Terminal: zsh with zinit plugins
    - Package manager: Nix for system packages
    - Git workflow: Feature branches with descriptive commit messages

    ## Code Standards
    - JavaScript/TypeScript: Use ESLint and Prettier
    - Ruby: Follow Rubocop guidelines
    - Nix: 2-space indentation, clear module structure
    - Always run linting and tests before committing

    ## Workflow Preferences
    - Test-driven development when appropriate
    - Small, focused commits with clear messages
    - Documentation for complex logic
    - Performance considerations for production code

    ## Tools and Commands
    - Build system: Managed through nix flake
    - Testing: Project-specific test runners (npm test, bundle exec rspec, etc.)
    - Deployment: Automated through CI/CD when available
  '';
}

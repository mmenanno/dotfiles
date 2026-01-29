{ config, mcpServers, mkHomebrewWrapper, githubMcpToken, ... }:

let
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
    "git branch:*"
    "git stash:*"
    "git fetch:*"
    "git remote:*"
    "git ls-tree:*"
    "git rev-parse:*"
    "git merge-base:*"
  ];
  safeShellCommands = [
    "ls:*"
    "ll:*"
    "la:*"
    "eza:*"
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
    "mv:*"
    "zip:*"
    "unzip:*"
    # Modern CLI tools
    "bat:*"
    "rg:*"
    "fd:*"
    "fzf:*"
    "jq:*"
    "yq:*"
    "delta:*"
    # Additional safe utilities
    "touch:*"
    "ln:*"
    "hostname"
    "id"
    "groups"
    "xargs:*"
    "tee:*"
    "less:*"
    "more:*"
    "tr:*"
    "column:*"
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
    "support.anthropic.com"
    "github.blog"
    "modelcontextprotocol.io"
    "claude.ai"
    "www.anthropic.com"
    "tailscale.com"
    # Ruby/Rails ecosystem
    "rubygems.org"
    "ruby-lang.org"
    "rubyonrails.org"
    "bundler.io"
    "guides.rubyonrails.org"
    "api.rubyonrails.org"
    # Nix ecosystem
    "nixos.org"
    "nixos.wiki"
    "home-manager-options.extranix.com"
  ];
  toBashPermissions = commands: map (cmd: "Bash(${cmd})") commands;
  toReadPermissions = files: map (file: "Read(${file})") files;
  toWebFetchPermissions = domains: map (domain: "WebFetch(domain:${domain})") domains;
in
{
  # Set GITHUB_PERSONAL_ACCESS_TOKEN for the official Claude Code GitHub plugin
  home.sessionVariables = {
    GITHUB_PERSONAL_ACCESS_TOKEN = githubMcpToken;
  };

  # Create symlink at ~/.local/bin/claude to satisfy Claude Code's native installation detection
  # This is needed because the TUI checks for the binary at this location when install method is "native"
  home.file.".local/bin/claude".source = config.lib.file.mkOutOfStoreSymlink "/opt/homebrew/bin/claude";

  programs.claude-code = {
    enable = true;
    # Use Homebrew-installed claude-code for faster updates
    package = mkHomebrewWrapper {
      name = "claude-code";
      homebrewBinary = "claude";
      nixBinary = "claude";
    };

    settings = {
      statusLine = {
        type = "command";
        # Use fish shell for status line to escape wrappers showing in the prompt
        command = "STARSHIP_SHELL=fish STARSHIP_CONFIG=$HOME/.config/starship.toml starship prompt | head -1";

      };
      includeCoAuthoredBy = false;
      theme = "dark";
      autoUpdates = true;
      verbose = false;
      cleanupPeriodDays = 20;
      enabledPlugins = {
        "claude-code-setup@claude-plugins-official" = true;
        "claude-md-management@claude-plugins-official" = true;
        "code-review@claude-plugins-official" = true;
        "code-simplifier@claude-plugins-official" = true;
        "commit-commands@claude-plugins-official" = true;
        "frontend-design@claude-plugins-official" = true;
        "github@claude-plugins-official" = true;
        "playwright@claude-plugins-official" = true;
        "pr-review-toolkit@claude-plugins-official" = true;
        "ralph-loop@claude-plugins-official" = true;
        "superpowers@claude-plugins-official" = true;
      };
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
            "nix-shell:*"
            "nix eval:*"
            "nix build:*"
            "nix develop:*"
            "nix search:*"
            # Starship helpers for status line debugging
            "starship config get:*"
            "starship print-config:*"
            "defaults:*"
            # Common shell helpers and project scripts
            "cp:*"
            "bash:*"
            "nx:*"
            # Git quality-of-life
            "git checkout:*"
            "git pull:*"
            "git reset:*"
          ])
          ++ [ "WebSearch" ]
          ++ (toWebFetchPermissions webDomains)
          ++ [ "Bash(gh repo view:*)" "Bash(gh release:*)" ]
          ++ (toBashPermissions [
            "brew search:*"
            "brew list:*"
            "brew info:*"
            "defaults read:*"
            "grep:*"
            "mkdir:*"
            "mise:*"
            # Python tools
            "python3:*"
            "pip3:*"
            # Node/npm tools
            "node:*"
            "npm install:*"
            "npm run:*"
            "npm uninstall:*"
            "npm search:*"
            "npx:*"
            # Document and linting tools
            "pandoc:*"
            "markdownlint:*"
            # 1Password CLI
            "op:*"
          ])
          # GitHub MCP actions used by workflows/debugging
          ++ [
            "mcp__github__list_workflows"
            "mcp__github__list_workflow_runs"
            "mcp__github__get_workflow_run"
            "mcp__github__list_workflow_jobs"
            "mcp__github__create_pull_request"
            "mcp__github__pull_request_read"
            "mcp__github__get_commit"
            "mcp__github__get_file_contents"
            "mcp__github__list_commits"
            "mcp__github__list_branches"
            "mcp__github__get_issue"
            "mcp__github__get_issue_comments"
            "mcp__github__list_issues"
            "mcp__github__list_pull_requests"
            "mcp__github__search_pull_requests"
            "mcp__github__search_issues"
            "mcp__github__search_code"
            "mcp__github__search_repositories"
            "mcp__github__search_users"
            "mcp__github__list_releases"
            "mcp__github__get_latest_release"
            "mcp__github__list_tags"
            "mcp__github__get_tag"
            "mcp__github__get_me"
            "mcp__github__get_teams"
            "mcp__github__get_team_members"
          ];
        ask = toBashPermissions [
          "git push:*"
          "git rebase:*"
          "git merge:*"
          "rm:*"
          "sudo:*"
          "chmod:*"
          "brew install:*"
          "brew upgrade:*"
        ];
        deny = [];
        additionalDirectories = [];
        defaultMode = "acceptEdits";
      };
    };

    # Use shared MCP servers but exclude GitHub (Claude Code has official GitHub plugin)
    mcpServers = builtins.removeAttrs mcpServers [ "github" ];
  };
}

{ config, mcpServers, mkHomebrewWrapper, ... }:

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
    "support.anthropic.com"
    "github.blog"
  ];
  toBashPermissions = commands: map (cmd: "Bash(${cmd})") commands;
  toReadPermissions = files: map (file: "Read(${file})") files;
  toWebFetchPermissions = domains: map (domain: "WebFetch(domain:${domain})") domains;
in
{
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
        "ralph-loop@claude-plugins-official" = true;
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
          ++ [ "Bash(gh repo view:*)" ]
          ++ (toBashPermissions [
            "brew search:*"
            "defaults read:*"
            "grep:*"
            "mkdir:*"
            "mise:*"
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
          "rm:*"
          "sudo:*"
          "chmod:*"
        ];
        deny = [];
        additionalDirectories = [];
        defaultMode = "acceptEdits";
      };
    };

    inherit mcpServers;
  };
}

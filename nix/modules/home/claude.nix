{ config, lib, pkgs, homeDirectory, mcpServers, mkHomebrewWrapper, githubMcpToken, ... }:

let
  # --- Development tool commands (npm, cargo, pytest, go, make) ---
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
  # --- Ruby/Rails ecosystem (bundle, rake, rails, rspec, rubocop, etc.) ---
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
  # --- Git operations (status, diff, log, commit, branch, etc.) ---
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
  # --- Safe read-only shell commands (ls, cat, find, stat, curl, etc.) ---
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
  # --- Safe file read patterns (package.json, Gemfile, READMEs, etc.) ---
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
  # --- Allowed web domains for fetching (GitHub, docs, Nix, Ruby/Rails) ---
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
    # Apple/macOS admin
    "gdmf.apple.com"
    "ipsw.me"
    "ipswdownloads.docs.apiary.io"
    # General interest
    "steamcommunity.com"
  ];
  # --- Permission list builders ---
  toBashPermissions = commands: map (cmd: "Bash(${cmd})") commands;
  toReadPermissions = files: map (file: "Read(${file})") files;
  toWebFetchPermissions = domains: map (domain: "WebFetch(domain:${domain})") domains;

  hooksDir = "${homeDirectory}/.claude/hooks";
in
{
  home = {
    # Set GITHUB_PERSONAL_ACCESS_TOKEN for the official Claude Code GitHub plugin
    sessionVariables = {
      GITHUB_PERSONAL_ACCESS_TOKEN = githubMcpToken;
      CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
    };

    # Install it2 CLI for Claude Code agent team split panes in iTerm2
    activation.installIt2 = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${pkgs.pipx}/bin/pipx install it2 2>/dev/null || \
        ${pkgs.pipx}/bin/pipx upgrade it2 2>/dev/null || true
    '';

    file = {
      # Create symlink at ~/.local/bin/claude to satisfy Claude Code's native installation detection
      # This is needed because the TUI checks for the binary at this location when install method is "native"
      ".local/bin/claude".source = config.lib.file.mkOutOfStoreSymlink "/opt/homebrew/bin/claude";

      # Statusline: model name + context progress bar + starship prompt
      ".claude/hooks/statusline.js".text = ''
        let input = "";
        process.stdin.setEncoding("utf8");
        process.stdin.on("data", chunk => input += chunk);
        process.stdin.on("end", () => {
          try {
            const data = JSON.parse(input);
            const model = data.model?.display_name || "";
            const remaining = data.context_window?.remaining_percentage;
            const parts = [];
            if (model) parts.push("\x1b[2m" + model + "\x1b[0m");
            if (remaining != null) {
              const rawUsed = Math.max(0, Math.min(100, 100 - Math.round(remaining)));
              const used = Math.min(100, Math.round((rawUsed / 80) * 100));
              const filled = Math.floor(used / 10);
              const bar = "▰".repeat(filled) + "▱".repeat(10 - filled);
              let color;
              let prefix = "";
              if (used < 63) color = "32";
              else if (used < 81) color = "33";
              else if (used < 95) color = "38;5;208";
              else { color = "5;31"; prefix = "🚨 "; }
              parts.push("\x1b[" + color + "m" + prefix + bar + " " + used + "%" + "\x1b[0m");
            }
            process.stdout.write(parts.join(" │ "));
          } catch (e) {}
        });
      '';
      ".claude/hooks/statusline.sh" = {
        executable = true;
        text = ''
          #!/bin/bash
          input=$(cat)
          info=$(echo "$input" | node "${hooksDir}/statusline.js" 2>/dev/null || true)
          star=$(STARSHIP_SHELL=fish STARSHIP_CONFIG="$HOME/.config/starship.toml" starship prompt 2>/dev/null | head -1 || true)
          if [ -n "$info" ] && [ -n "$star" ]; then
            printf '%s %s' "$info" "$star"
          elif [ -n "$info" ]; then
            printf '%s' "$info"
          else
            printf '%s' "$star"
          fi
        '';
      };
    };
  };

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
        command = "${hooksDir}/statusline.sh";
      };
      includeCoAuthoredBy = false;
      theme = "dark";
      autoUpdates = true;
      teammateMode = "tmux";
      verbose = false;
      respectGitignore = false;
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
        "plugin-dev@claude-plugins-official" = false;
        "pr-review-toolkit@claude-plugins-official" = true;
        "ralph-loop@claude-plugins-official" = true;
        "superpowers@claude-plugins-official" = true;
        "gopls-lsp@claude-plugins-official" = true;
        "csharp-lsp@claude-plugins-official" = true;
        "rust-analyzer-lsp@claude-plugins-official" = true;
        "php-lsp@claude-plugins-official" = true;
        "jdtls-lsp@claude-plugins-official" = true;
        "clangd-lsp@claude-plugins-official" = true;
        "swift-lsp@claude-plugins-official" = true;
        "kotlin-lsp@claude-plugins-official" = true;
        "lua-lsp@claude-plugins-official" = true;
        # Local plugins
        "gwa@local-plugins" = true;
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
            # Claude CLI management
            "claude plugin:*"
            # Full-path grep (Nix PATH resolution)
            "/usr/bin/grep:*"
          ])
          # GitHub MCP plugin - read-only tools
          ++ [
            "mcp__plugin_github_github__get_me"
            "mcp__plugin_github_github__get_commit"
            "mcp__plugin_github_github__get_file_contents"
            "mcp__plugin_github_github__get_label"
            "mcp__plugin_github_github__get_latest_release"
            "mcp__plugin_github_github__get_release_by_tag"
            "mcp__plugin_github_github__get_tag"
            "mcp__plugin_github_github__issue_read"
            "mcp__plugin_github_github__list_branches"
            "mcp__plugin_github_github__list_commits"
            "mcp__plugin_github_github__list_issues"
            "mcp__plugin_github_github__list_pull_requests"
            "mcp__plugin_github_github__list_releases"
            "mcp__plugin_github_github__list_tags"
            "mcp__plugin_github_github__pull_request_read"
            "mcp__plugin_github_github__search_code"
            "mcp__plugin_github_github__search_issues"
            "mcp__plugin_github_github__search_pull_requests"
            "mcp__plugin_github_github__search_repositories"
            "mcp__plugin_github_github__search_users"
          ]
          # GitHub MCP plugin - safe write tools
          ++ [
            "mcp__plugin_github_github__create_branch"
            "mcp__plugin_github_github__create_pull_request"
            "mcp__plugin_github_github__update_pull_request"
            "mcp__plugin_github_github__update_pull_request_branch"
            "mcp__plugin_github_github__add_issue_comment"
            "mcp__plugin_github_github__issue_write"
            "mcp__plugin_github_github__request_copilot_review"
            "mcp__plugin_github_github__pull_request_review_write"
            "mcp__plugin_github_github__add_comment_to_pending_review"
            "mcp__plugin_github_github__sub_issue_write"
          ]
          # Playwright MCP plugin - read-only/observational
          ++ [
            "mcp__plugin_playwright_playwright__browser_snapshot"
            "mcp__plugin_playwright_playwright__browser_take_screenshot"
            "mcp__plugin_playwright_playwright__browser_console_messages"
            "mcp__plugin_playwright_playwright__browser_network_requests"
            "mcp__plugin_playwright_playwright__browser_tabs"
          ]
          # Playwright MCP plugin - standard interaction
          ++ [
            "mcp__plugin_playwright_playwright__browser_navigate"
            "mcp__plugin_playwright_playwright__browser_navigate_back"
            "mcp__plugin_playwright_playwright__browser_click"
            "mcp__plugin_playwright_playwright__browser_type"
            "mcp__plugin_playwright_playwright__browser_fill_form"
            "mcp__plugin_playwright_playwright__browser_select_option"
            "mcp__plugin_playwright_playwright__browser_press_key"
            "mcp__plugin_playwright_playwright__browser_hover"
            "mcp__plugin_playwright_playwright__browser_close"
            "mcp__plugin_playwright_playwright__browser_resize"
            "mcp__plugin_playwright_playwright__browser_wait_for"
            "mcp__plugin_playwright_playwright__browser_handle_dialog"
            "mcp__plugin_playwright_playwright__browser_install"
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
        ]
        # GitHub MCP plugin - mutating tools requiring confirmation
        ++ [
          "mcp__plugin_github_github__merge_pull_request"
          "mcp__plugin_github_github__push_files"
          "mcp__plugin_github_github__create_or_update_file"
          "mcp__plugin_github_github__delete_file"
          "mcp__plugin_github_github__create_repository"
          "mcp__plugin_github_github__fork_repository"
          "mcp__plugin_github_github__assign_copilot_to_issue"
        ]
        # Playwright MCP plugin - tools requiring confirmation
        ++ [
          "mcp__plugin_playwright_playwright__browser_evaluate"
          "mcp__plugin_playwright_playwright__browser_run_code"
          "mcp__plugin_playwright_playwright__browser_file_upload"
          "mcp__plugin_playwright_playwright__browser_drag"
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

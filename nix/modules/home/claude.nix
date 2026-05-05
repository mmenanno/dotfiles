{ config, lib, pkgs, homeDirectory, mcpServers, mkHomebrewWrapper, githubMcpToken, isWorkMachine ? false, ... }:

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
  ] ++ lib.concatMap (tool: [
    "bundle exec ${tool}:*"
    "${tool}:*"
    "bin/${tool}:*"
  ]) coreRubyTools;
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
  # --- Safe shell commands (ls, cat, find, stat, curl, mv, touch, etc.) ---
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

  # --- GitHub MCP plugin permissions ---
  ghMcp = tool: "mcp__plugin_github_github__${tool}";
  githubMcpReadTools = map ghMcp [
    "get_me"
    "get_commit"
    "get_file_contents"
    "get_label"
    "get_latest_release"
    "get_release_by_tag"
    "get_tag"
    "get_team_members"
    "get_teams"
    "get_copilot_job_status"
    "issue_read"
    "list_branches"
    "list_commits"
    "list_issues"
    "list_issue_types"
    "list_pull_requests"
    "list_releases"
    "list_tags"
    "pull_request_read"
    "search_code"
    "search_issues"
    "search_pull_requests"
    "search_repositories"
    "search_users"
  ];
  githubMcpWriteTools = map ghMcp [
    "create_branch"
    "create_pull_request"
    "update_pull_request"
    "update_pull_request_branch"
    "add_issue_comment"
    "add_reply_to_pull_request_comment"
    "issue_write"
    "request_copilot_review"
    "pull_request_review_write"
    "add_comment_to_pending_review"
    "sub_issue_write"
  ];
  githubMcpAskTools = map ghMcp [
    "merge_pull_request"
    "push_files"
    "create_or_update_file"
    "delete_file"
    "create_repository"
    "fork_repository"
    "assign_copilot_to_issue"
    "create_pull_request_with_copilot"
    "run_secret_scanning"
  ];
  # --- Playwright MCP plugin permissions ---
  pwMcp = tool: "mcp__plugin_playwright_playwright__${tool}";
  playwrightMcpReadTools = map pwMcp [
    "browser_snapshot"
    "browser_take_screenshot"
    "browser_console_messages"
    "browser_network_requests"
    "browser_tabs"
  ];
  playwrightMcpInteractionTools = map pwMcp [
    "browser_navigate"
    "browser_navigate_back"
    "browser_click"
    "browser_type"
    "browser_fill_form"
    "browser_select_option"
    "browser_press_key"
    "browser_hover"
    "browser_close"
    "browser_resize"
    "browser_wait_for"
    "browser_handle_dialog"
    "browser_install"
  ];
  playwrightMcpAskTools = map pwMcp [
    "browser_evaluate"
    "browser_run_code"
    "browser_file_upload"
    "browser_drag"
  ];
  # --- Notion MCP plugin permissions ---
  notionMcp = tool: "mcp__claude_ai_Notion__notion-${tool}";
  notionMcpReadTools = map notionMcp [
    "search"
    "fetch"
    "get-comments"
    "get-teams"
    "get-users"
  ];
  notionMcpAskTools = map notionMcp [
    "create-comment"
    "create-database"
    "create-pages"
    "create-view"
    "duplicate-page"
    "move-pages"
    "update-data-source"
    "update-page"
    "update-view"
  ];
  # --- Work-only claude.ai MCP integrations ---
  # Glean (search/chat — all read)
  gleanMcp = tool: "mcp__claude_ai_Glean__${tool}";
  gleanMcpReadTools = map gleanMcp [ "search" "chat" "gmail_search" "user_activity" ];
  # Gmail
  gmailMcp = tool: "mcp__claude_ai_Gmail__${tool}";
  gmailMcpReadTools = map gmailMcp [
    "gmail_get_profile"
    "gmail_list_drafts"
    "gmail_list_labels"
    "gmail_read_message"
    "gmail_read_thread"
    "gmail_search_messages"
  ];
  gmailMcpAskTools = map gmailMcp [ "gmail_create_draft" ];
  # Google Calendar
  gCalMcp = tool: "mcp__claude_ai_Google_Calendar__${tool}";
  gCalMcpReadTools = map gCalMcp [
    "gcal_list_calendars"
    "gcal_list_events"
    "gcal_get_event"
    "gcal_find_meeting_times"
    "gcal_find_my_free_time"
  ];
  gCalMcpAskTools = map gCalMcp [
    "gcal_create_event"
    "gcal_update_event"
    "gcal_delete_event"
    "gcal_respond_to_event"
  ];
  # Slack (claude.ai integration — distinct from slack plugin)
  slackAiMcp = tool: "mcp__claude_ai_Slack__${tool}";
  slackAiMcpReadTools = map slackAiMcp [
    "slack_read_canvas"
    "slack_read_channel"
    "slack_read_thread"
    "slack_read_user_profile"
    "slack_search_channels"
    "slack_search_public"
    "slack_search_public_and_private"
    "slack_search_users"
  ];
  slackAiMcpAskTools = map slackAiMcp [
    "slack_create_canvas"
    "slack_schedule_message"
    "slack_send_message"
    "slack_send_message_draft"
    "slack_update_canvas"
  ];
  # Snowflake (agentic — always ask)
  snowflakeAiMcpAskTools = [ "mcp__claude_ai_Snowflake__data-doula-agent" ];

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
      if ! ${pkgs.pipx}/bin/pipx list --short 2>/dev/null | grep -q '^it2 '; then
        ${pkgs.pipx}/bin/pipx install it2 >/dev/null 2>&1 || true
      fi
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
      respectGitignore = false;
      skipAllowlistPrompt = true;
      skipAutoPermissionPrompt = true;
      cleanupPeriodDays = 20;
      includeCoAuthoredBy = false;
      model = "opus[1m]";
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
          # gh CLI fallback — prefer GitHub MCP plugin (see ~/.claude/CLAUDE.md)
          ++ (toBashPermissions [
            "gh repo view:*"
            "gh release:*"
            # gh CLI operations with no MCP equivalent
            "gh run:*"
            "gh pr checkout:*"
            "gh pr view:*"
            "gh pr diff:*"
          ])
          ++ (toBashPermissions [
            "brew search:*"
            "brew list:*"
            "brew info:*"
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
          # GitHub MCP plugin
          ++ githubMcpReadTools
          ++ githubMcpWriteTools
          # Playwright MCP plugin
          ++ playwrightMcpReadTools
          ++ playwrightMcpInteractionTools
          # Notion MCP plugin
          ++ notionMcpReadTools
          # Work-only claude.ai MCPs
          ++ (lib.optionals isWorkMachine (
            gleanMcpReadTools
            ++ gmailMcpReadTools
            ++ gCalMcpReadTools
            ++ slackAiMcpReadTools
          ));
        deny = [];
        ask = toBashPermissions [
          "git push:*"
          "git rebase:*"
          "git merge:*"
          "rm:*"
          "sudo:*"
          "chmod:*"
          "brew install:*"
          "brew upgrade:*"
          # gh CLI operations requiring confirmation
          "gh pr merge:*"
          "gh api:*"
        ]
        ++ githubMcpAskTools
        ++ playwrightMcpAskTools
        ++ notionMcpAskTools
        ++ (lib.optionals isWorkMachine (
          gmailMcpAskTools
          ++ gCalMcpAskTools
          ++ slackAiMcpAskTools
          ++ snowflakeAiMcpAskTools
        ));
        defaultMode = "auto";
        additionalDirectories = [];
      };
      statusLine = {
        type = "command";
        command = "${hooksDir}/statusline.sh";
      };
      enabledPlugins = {
        "claude-code-setup@claude-plugins-official" = true;
        "claude-md-management@claude-plugins-official" = true;
        "code-simplifier@claude-plugins-official" = true;
        "commit-commands@claude-plugins-official" = true;
        "frontend-design@claude-plugins-official" = true;
        "github@claude-plugins-official" = true;
        "playwright@claude-plugins-official" = true;
        "plugin-dev@claude-plugins-official" = false;
        "pr-review-toolkit@claude-plugins-official" = true;
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
        "ruby-lsp@claude-plugins-official" = true;
        "notion-markdown@babylist" = isWorkMachine;
        "datadog-analytics@babylist" = isWorkMachine;
        "skill-creator@claude-plugins-official" = false;

        # Local plugins
        "gwa@local-plugins" = !isWorkMachine;
      };
      extraKnownMarketplaces = lib.optionalAttrs isWorkMachine {
        babylist = {
          source = {
            source = "github";
            repo = "babylist/claude-plugins";
          };
        };
      };
      autoDreamEnabled = true;
      autoUpdates = true;
      teammateMode = "auto";
      theme = "dark";
      verbose = false;
    };

    # Use shared MCP servers but exclude GitHub (Claude Code has official GitHub plugin)
    mcpServers = builtins.removeAttrs mcpServers [ "github" ];
  };
}

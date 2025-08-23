{ config, pkgs, ... }:

{
  home.file.".claude/settings.json".text = builtins.toJSON {
    statusLine = {
      type = "command";
      command = "input=$(cat); cwd=$(echo \"$input\" | jq -r '.workspace.current_dir'); cd \"$cwd\" 2>/dev/null || true; STARSHIP_CONFIG=$HOME/.config/starship.toml starship prompt | sed 's/%{\\([^}]*\\)%}/\\x1b[\\1/g'";
    };

    # Git configuration
    includeCoAuthoredBy = false;

    # Cleanup configuration
    cleanupPeriodDays = 20;

    # Permissions - generated programmatically for maintainability
    permissions = 
      let
        # Define permission groups
        devTools = ["npm run lint" "npm run test:*" "npm run build" "yarn lint" "cargo check" "cargo test" "pytest:*" "go test:*" "make test"];
        rubyTools = ["bundle install" "bundle exec rspec:*" "bundle exec rails test:*" "bundle exec rubocop:*" "rails generate:*" "rails db:migrate" "rails db:rollback" "rails db:seed" "rake test:*" "rspec:*" "rubocop:*"];
        gitOps = ["git status" "git diff:*" "git log:*" "git show:*" "git add:*" "git commit:*" "git config:*"];
        safeReads = ["package.json" "Gemfile" "Gemfile.lock" "Rakefile" "Makefile" "README.md" "~/.zshrc" "~/.gitconfig" "**/*.md" "**/*.toml"];
        
        # Helper to create Bash permissions
        toBashPermissions = commands: map (cmd: "Bash(${cmd})") commands;
        toReadPermissions = files: map (file: "Read(${file})") files;
      in {
        allow = [
          # Development & Testing Tools
        ] ++ toBashPermissions devTools ++ toBashPermissions rubyTools ++ [
          # Safe Git Operations  
        ] ++ toBashPermissions gitOps ++ [
          # Safe Read Operations
        ] ++ toReadPermissions safeReads ++ 
        
        # Nix Operations
        toBashPermissions ["nix flake update:*" "/usr/bin/env nix flake:*" "nixup:*" "nix flake metadata:*" "nix flake check:*"] ++
        
        # Web Access - domains and search
        ["WebSearch"] ++ 
        (map (domain: "WebFetch(domain:${domain})") ["github.com" "raw.githubusercontent.com" "api.github.com" "starship.rs" "www.nerdfonts.com" "gist.github.com" "nix-darwin.github.io" "nix-community.github.io" "docs.anthropic.com"]) ++
        ["Bash(gh repo view:*)"] ++
        
        # macOS and System Operations
        toBashPermissions ["brew search:*" "defaults read:*" "grep:*" "mkdir:*" "mise:*"];
        
      ask = toBashPermissions ["git push:*" "rm:*" "sudo:*" "chmod:*"];
      deny = [];
      additionalDirectories = [];
      defaultMode = "acceptEdits";
    };
  };

  # Create base plugins config with nix, but make it writable for Claude
  home.activation.claudePluginsConfig = ''
    PLUGINS_DIR="$HOME/.claude/plugins"
    CONFIG_FILE="$PLUGINS_DIR/config.json"
    BASE_CONFIG='${builtins.toJSON { repositories = {}; }}'

    # Create plugins directory if it doesn't exist
    mkdir -p "$PLUGINS_DIR"

    if [[ ! -f "$CONFIG_FILE" ]]; then
      # File doesn't exist - create it with our base config
      echo "Creating initial Claude plugins config..."
      echo "$BASE_CONFIG" > "$CONFIG_FILE"
      chmod 644 "$CONFIG_FILE"
    else
      # File exists - compare content with our expected config
      # Normalize both JSONs using jq to handle formatting differences
      EXISTING_NORMALIZED=$(cat "$CONFIG_FILE" | jq -c -S .)
      BASE_NORMALIZED=$(echo "$BASE_CONFIG" | jq -c -S .)

      if [[ "$EXISTING_NORMALIZED" == "$BASE_NORMALIZED" ]]; then
        # Content matches - all good, ensure it's writable
        chmod 644 "$CONFIG_FILE"
      else
        # Content differs - output error since we should update our declarative config
        echo "ERROR: Claude plugins config exists but differs from our declarative configuration!"
        echo "Expected: $BASE_NORMALIZED"
        echo "Actual:   $EXISTING_NORMALIZED"
        echo "Please update the declarative config in nix/modules/claude.nix to match the actual file,"
        echo "or remove $CONFIG_FILE to let nix recreate it with the base configuration."
        exit 1
      fi
    fi
  '';

  # User-specific Claude configuration
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

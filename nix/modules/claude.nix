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

    # Permissions
    permissions = {
      allow = [
        # Development & Testing
        "Bash(npm run lint)"
        "Bash(npm run test:*)"
        "Bash(npm run build)"
        "Bash(yarn lint)"
        "Bash(cargo check)"
        "Bash(cargo test)"
        "Bash(pytest:*)"
        "Bash(go test:*)"
        "Bash(make test)"
        "Bash(bundle install)"
        "Bash(bundle exec rspec:*)"
        "Bash(bundle exec rails test:*)"
        "Bash(bundle exec rubocop:*)"
        "Bash(rails generate:*)"
        "Bash(rails db:migrate)"
        "Bash(rails db:rollback)"
        "Bash(rails db:seed)"
        "Bash(rake test:*)"
        "Bash(rspec:*)"
        "Bash(rubocop:*)"

        # Safe Git Operations
        "Bash(git status)"
        "Bash(git diff:*)"
        "Bash(git log:*)"
        "Bash(git show:*)"
        "Bash(git add:*)"
        "Bash(git commit:*)"
        "Bash(git config:*)"

        # Safe Read Operations
        "Read(package.json)"
        "Read(Gemfile)"
        "Read(Gemfile.lock)"
        "Read(Rakefile)"
        "Read(Makefile)"
        "Read(README.md)"
        "Read(~/.zshrc)"
        "Read(~/.gitconfig)"
        "Read(**/*.md)"
        "Read(**/*.toml)"

        # Nix Operations
        "Bash(nix flake update:*)"
        "Bash(/usr/bin/env nix flake:*)"
        "Bash(nixup:*)"
        "Bash(nix flake metadata:*)"
        "Bash(nix flake check:*)"

        # Web Access
        "WebSearch"
        "Bash(gh repo view:*)"
        "WebFetch(domain:github.com)"
        "WebFetch(domain:raw.githubusercontent.com)"
        "WebFetch(domain:api.github.com)"
        "WebFetch(domain:starship.rs)"
        "WebFetch(domain:www.nerdfonts.com)"
        "WebFetch(domain:gist.github.com)"
        "WebFetch(domain:nix-darwin.github.io)"
        "WebFetch(domain:nix-community.github.io)"
        "WebFetch(domain:docs.anthropic.com)"

        # macOS Operations
        "Bash(brew search:*)"
        "Bash(defaults read:*)"

        # System Utilities
        "Bash(grep:*)"
        "Bash(mkdir:*)"
        "Bash(mise:*)"
      ];
      ask = [
        "Bash(git push:*)"
        "Bash(rm:*)"
        "Bash(sudo:*)"
        "Bash(chmod:*)"
      ];
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

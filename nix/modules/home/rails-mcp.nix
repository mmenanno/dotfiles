{ lib, pkgs, ... }:

{
  home.activation = {
    # Ensure rails-mcp-server gem is available and provide stable wrappers
    installRailsMcpServer = lib.hm.dag.entryAfter ["writeBoundary"] ''
      set -euo pipefail

      export PATH="${pkgs.mise}/bin:$PATH:/usr/bin:/bin:/opt/homebrew/bin:/usr/local/bin"

      # Determine ruby version from ~/.ruby-version if present; otherwise use latest configured by mise
      ruby_version="$(cat "$HOME/.ruby-version" 2>/dev/null || echo "latest")"

      echo -e "\033[34mEnsuring rails-mcp-server gem is installed/updated (Ruby $ruby_version)...\033[0m"
      if ! mise x ruby@"$ruby_version" -- gem list -i rails-mcp-server >/dev/null 2>&1; then
        echo -e "\033[33mInstalling rails-mcp-server gem...\033[0m"
        mise x ruby@"$ruby_version" -- gem install rails-mcp-server --no-document >/dev/null
        echo -e "\033[32mrails-mcp-server gem installed\033[0m"
      else
        echo -e "\033[33mUpdating rails-mcp-server gem (if needed)...\033[0m"
        mise x ruby@"$ruby_version" -- gem update rails-mcp-server --no-document >/dev/null || true
        echo -e "\033[32mrails-mcp-server gem ensured up-to-date\033[0m"
      fi
    '';

    # Ensure official guide resources are present and refreshed periodically
    updateRailsMcpResources = lib.hm.dag.entryAfter ["installRailsMcpServer"] ''
      set -euo pipefail

      export PATH="${pkgs.mise}/bin:$PATH:/usr/bin:/bin:/opt/homebrew/bin:/usr/local/bin"

      # Refresh resource packs; tolerate network or server hiccups without failing the build
      for pack in rails turbo stimulus kamal; do
        echo -e "\033[34mEnsuring rails-mcp-server resources for '$pack'...\033[0m"
        if ! mise x ruby -- rails-mcp-server-download-resources "$pack" >/dev/null 2>&1; then
          echo -e "\033[33mWarning: failed to update resources for '$pack' (will continue)\033[0m"
        else
          echo -e "\033[32mResources ensured for '$pack'\033[0m"
        fi
      done
    '';

    # Ensure projects.yml exists with a helpful template
    ensureRailsMcpConfig = lib.hm.dag.entryAfter ["updateRailsMcpResources"] ''
    set -euo pipefail

    config_dir="$HOME/.config/rails-mcp"
    projects_file="$config_dir/projects.yml"
    mkdir -p "$config_dir"

    if [ ! -f "$projects_file" ]; then
      cat > "$projects_file" <<'YAML'
# rails-mcp-server projects configuration
# Add your Rails apps here. Example:
#
# projects:
#   - name: myapp
#     path: /Users/you/dev/myapp
#     env: development
#
projects: []
YAML
      echo -e "\033[34mCreated rails MCP projects file at $projects_file\033[0m"
    fi
  '';
  };
}



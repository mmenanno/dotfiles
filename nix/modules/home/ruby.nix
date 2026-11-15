{ config, lib, pkgs, ... }:

let
  latestRubyVersion = "4.0.7";
  rubyVersions = [
    latestRubyVersion
  ];
in
{
  home = {
    activation = {
      installRubyVersions = lib.hm.dag.entryAfter ["writeBoundary"] ''
        export PATH="${config.programs.mise.package}/bin:$PATH:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"

        echo -e "\033[0;34mℹ\033[0m Verifying Ruby installations..."
        for version in ${lib.escapeShellArgs rubyVersions}; do
          # Check for the binary, not just the folder: an interrupted install
          # leaves the folder behind, and mise's ruby shim then runs mise itself
          if [ -x "$HOME/.local/share/mise/installs/ruby/$version/bin/ruby" ]; then
            echo -e "\033[0;32m✓\033[0m Ruby $version installation verified"
          else
            echo -e "\033[1;33m!\033[0m Installing Ruby $version..."
            # A missing Ruby shouldn't stop the rest of the Mac being set up;
            # the next nx up retries it
            if mise install --force ruby@$version; then
              echo -e "\033[0;32m✓\033[0m Ruby $version installation completed"
            else
              echo -e "\033[1;33m!\033[0m Failed to install Ruby $version; nx up will try again"
            fi
          fi
        done
        echo -e "\033[0;34mℹ\033[0m Finished Ruby versions verification/installation"
      '';
    };

    file = {
      ".ruby-version".text = latestRubyVersion;

      # Bundler global configuration
      ".bundle/config".text = ''
        ---
        BUNDLE_IGNORE_FUNDING_REQUESTS: "true"
        BUNDLE_BUILD__MYSQL2: "--with-opt-dir=${lib.getDev pkgs.openssl}:${lib.getLib pkgs.openssl}"
      '';
    };
  };
}

{ lib, pkgs,... }:

let
  latestRubyVersion = "4.0.2";
  rubyVersions = [
    "3.4.8"
    "4.0.1"
    latestRubyVersion
  ];
in
{
  home = {
    activation = {
      installRubyVersions = lib.hm.dag.entryAfter ["writeBoundary"] ''
        export PATH="${pkgs.mise}/bin:$PATH:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"

        echo -e "\033[0;34mℹ\033[0m Verifying Ruby installations..."
        for version in ${lib.escapeShellArgs rubyVersions}; do
          if [ -d "$HOME/.local/share/mise/installs/ruby/$version" ]; then
            echo -e "\033[0;32m✓\033[0m Ruby $version installation verified"
          else
            echo -e "\033[1;33m!\033[0m Installing Ruby $version..."
            if ! mise install ruby@$version; then
              echo -e "\033[0;31m✗\033[0m Failed to install Ruby $version"
              exit 1
            fi
            echo -e "\033[0;32m✓\033[0m Ruby $version installation completed"
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
        BUNDLE_BUILD__MYSQL2: "--with-opt-dir=${pkgs.openssl}/lib"
      '';
    };
  };
}

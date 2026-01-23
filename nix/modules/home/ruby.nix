{ lib, pkgs,... }:

let
  latestRubyVersion = "4.0.1";
  rubyVersions = [
    "3.4.8"
    "4.0.0"
    latestRubyVersion
  ];
in
{
  home = {
    activation = {
      installRubyVersions = lib.hm.dag.entryAfter ["writeBoundary"] ''
        export PATH="${pkgs.mise}/bin:$PATH:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"

        echo -e "\033[34mVerifying Ruby installations...\033[0m"
        for version in ${lib.escapeShellArgs rubyVersions}; do
          if [ -d "$HOME/.local/share/mise/installs/ruby/$version" ]; then
            echo -e "\033[32mRuby $version installation verified\033[0m"
          else
            echo -e "\033[33mInstalling Ruby $version...\033[0m"
            mise install ruby@$version
            echo -e "\033[32mRuby $version installation completed\033[0m"
          fi
        done
        echo -e "\033[34mFinished Ruby versions verification/installation\033[0m"
      '';
    };

    file = {
      ".ruby-version".text = latestRubyVersion;

      # Bundler global configuration
      ".bundle/config".text = ''
        ---
        BUNDLE_IGNORE_FUNDING_REQUESTS: "true"
      '';
    };
  };
}

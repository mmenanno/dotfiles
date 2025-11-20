{ homeDirectory, pkgs, ... }:

let
  appsDir = "${homeDirectory}/Applications/";
  pwaAppsSourceDir = "${homeDirectory}/dotfiles/nix/files/pwa_apps";
in
{
  system.activationScripts.postActivation.text = ''
    echo -e "\033[0;34mChecking and linking PWA apps...\033[0m"

    # Loop through all .app directories in the source directory
    for app in ${pwaAppsSourceDir}/*.app; do
      appName=$(basename "$app")
      targetPath="${appsDir}/$appName"

      if [ ! -e "$targetPath" ]; then
        echo -e "\033[0;34mLinking $appName...\033[0m"
        ${pkgs.coreutils}/bin/ln -sf "$app" "$targetPath"
      else
        echo -e "\033[0;32m$appName is already linked.\033[0m"
      fi
    done

    echo -e "\033[0;34mPWA apps linking completed.\033[0m"
  '';
}

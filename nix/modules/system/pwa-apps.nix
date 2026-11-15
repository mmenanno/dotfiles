{ homeDirectory, username, pkgs, ... }:

let
  appsDir = "${homeDirectory}/Applications/";
  pwaAppsSourceDir = "${homeDirectory}/dotfiles/nix/files/pwa_apps";
in
{
  system.activationScripts.postActivation.text = ''
    echo -e "\033[0;34mℹ\033[0m Checking and linking PWA apps..."

    # A fresh Mac has no ~/Applications. Activation runs as root, so hand the
    # new folder to the user
    if [ ! -d "${appsDir}" ]; then
      mkdir -p "${appsDir}"
      chown ${username}:staff "${appsDir}"
    fi

    # Loop through all .app directories in the source directory
    for app in ${pwaAppsSourceDir}/*.app; do
      appName=$(basename "$app")
      targetPath="${appsDir}/$appName"

      if [ ! -e "$targetPath" ]; then
        echo -e "\033[0;34mℹ\033[0m Linking $appName..."
        ${pkgs.coreutils}/bin/ln -sf "$app" "$targetPath"
      else
        echo -e "\033[0;32m✓\033[0m $appName is already linked."
      fi
    done

    echo -e "\033[0;32m✓\033[0m PWA apps linking completed."
  '';
}

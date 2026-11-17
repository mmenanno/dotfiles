{
  pkgs,
  lib,
  homeDirectory,
  isWorkMachine ? false,
  ...
}:
# Scope: Home Manager. Finder settings that `defaults write` can't express:
# the sidebar favorites (an archived bookmark list) and view settings nested
# inside dictionaries (default sort). Flat Finder keys live in
# system-defaults.nix and home-manager-system-defaults.nix.
let
  finderSetup = pkgs.stdenv.mkDerivation {
    name = "finder-setup";
    src = ../../files/finder-setup.m;
    dontUnpack = true;
    buildPhase = ''
      $CC -fobjc-arc -O2 -framework Foundation -framework CoreServices "$src" -o finder-setup
    '';
    installPhase = ''
      install -Dm755 finder-setup "$out/bin/finder-setup"
    '';
  };

  # Sidebar Favorites, in order
  favorites = [
    "/Applications"
    "${homeDirectory}/Downloads"
    "${homeDirectory}/Documents"
    "${homeDirectory}/Movies"
    "${homeDirectory}/Pictures"
    "${homeDirectory}/Music"
    "${homeDirectory}/Desktop"
  ]
  ++ (if isWorkMachine then [ ] else [ "${homeDirectory}/MEGA" ]);

  # Keys inside com.apple.finder dictionaries; dots step into nested levels
  stringPrefs = {
    # Folders in icon view sort by name ("Use as Defaults" in View Options)
    "StandardViewSettings.IconViewSettings.arrangeBy" = "name";
    # Desktop: stacks grouped by kind, sorted by date added
    "DesktopViewSettings.GroupBy" = "Kind";
    "DesktopViewSettings.IconViewSettings.arrangeBy" = "dateAdded";
  };
  boolPrefs = {
    "StandardViewSettings.IconViewSettings.showItemInfo" = true;
  };

  args = lib.concatStringsSep " " (
    (map (p: "--favorite ${lib.escapeShellArg p}") favorites)
    ++ [ "--hide-hard-drives" ]
    ++ lib.mapAttrsToList (k: v: "--string ${lib.escapeShellArg k} ${lib.escapeShellArg v}") stringPrefs
    ++ lib.mapAttrsToList (k: v: "--bool ${lib.escapeShellArg k} ${lib.boolToString v}") boolPrefs
  );
in
{
  home.activation.finderSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -n "''${DRY_RUN:-}" ]; then
      echo -e "\033[0;34mℹ\033[0m Would apply Finder sidebar and view settings"
    elif ! finder_out=$(${finderSetup}/bin/finder-setup ${args}); then
      echo -e "\033[0;31m✗\033[0m Couldn't apply Finder sidebar and view settings"
    elif [ -z "$finder_out" ]; then
      echo -e "\033[0;32m✓\033[0m Finder sidebar and view settings are up to date"
    else
      while IFS= read -r line; do
        case "$line" in
          restart-finder) killall Finder 2>/dev/null || true ;;
          skipped*) echo -e "\033[1;33m!\033[0m Finder: $line" ;;
          *) echo -e "\033[0;32m✓\033[0m Finder: $line" ;;
        esac
      done <<< "$finder_out"
    fi
  '';
}

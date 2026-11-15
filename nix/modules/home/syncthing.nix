{ dotlib, ... }:
# Scope: Home (Home Manager), personal machine. Declares the Syncthing folders
# this Mac shares with the Unraid server. Syncthing.app itself comes from
# Homebrew; bin/syncthing-setup reads this file after `nx up` and adds any
# missing device or folder through Syncthing's API (receive-only until
# `nx syncthing promote`).
let
  # Not a secret: a device ID only identifies a device
  unraidDeviceId = dotlib.getEnvOrFallback "NIX_SYNCTHING_UNRAID_ID" "" "";

  folder = name: path: ignores: {
    id = "michael-macbook-${name}";
    label = name;
    inherit path ignores;
  };
in
{
  xdg.configFile."dotfiles/syncthing.json".text = builtins.toJSON {
    inherit unraidDeviceId;
    unraidName = "Unraid Server";
    folderDefaults = {
      fsWatcherEnabled = true;
      rescanIntervalS = 3600;
      order = "random";
    };
    folders = [
      (folder "desktop" "~/Desktop" [ ".DS_Store" ])
      (folder "dev" "~/dev" [ ])
      (folder "documents" "~/Documents" [ ])
      (folder "downloads" "~/Downloads" [ ])
      (folder "minecraft" "~/minecraft" [ ])
      (folder "movies" "~/Movies" [ ".DS_Store" ])
      (folder "music" "~/Music" [ ".DS_Store" ])
      (folder "pictures" "~/Pictures" [ ".DS_Store" "Photo Booth Library" "Photos Library.photoslibrary" ])
      (folder "tasks" "~/tasks" [ "/bunkr/downloads" "/bunkr/logs" ])
      (folder "writing" "~/writing" [ ])
    ];
  };
}

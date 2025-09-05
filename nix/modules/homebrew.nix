{ username, ... }: {
  homebrew = {
    enable = true;
    brews = [
      "libyaml"
      "mas"
    ];

    casks = [
      "1password@beta"
      "1password-cli"
      "adguard"
      "affinity-designer"
      "affinity-photo"
      "affinity-publisher"
      "battle-net"
      "chatgpt"
      "claude"
      "claude-code"
      "codex"
      "cursor"
      "daisydisk"
      "db-browser-for-sqlite"
      "discord"
      "docker-desktop"
      "downie"
      "ea"
      "filebot"
      "firefox"
      "gas-mask"
      "git-credential-manager"
      "google-chrome"
      "handbrake-app"
      "imageoptim"
      "jordanbaird-ice"
      "kindle-previewer"
      "logi-options+"
      "logitune"
      "logseq"
      "lulu"
      "maccy"
      "makemkv"
      "mediainfo"
      "megasync"
      "minecraft"
      "obsidian"
      "pearcleaner"
      "plex"
      "postman"
      "proton-drive"
      "proton-mail"
      "proton-mail-bridge"
      "proton-pass"
      "protonvpn"
      "proxyman"
      "qlvideo"
      "quicklook-json"
      "rectangle"
      "renpy"
      "scummvm-app"
      "sequel-ace"
      "session"
      "signal"
      "slack"
      "steam"
      "syncthing-app"
      "tailscale-app"
      "teamviewer"
      "telegram"
      "textual"
      "the-unarchiver"
      "torrent-file-editor"
      "transmit"
      "unraid-usb-creator-next"
      "visual-studio-code"
      "vlc"
      "webpquicklook"
      "whatsapp"
      "zoom"
    ];

    masApps = {
        "1Password for Safari" = 1569813296;
        "Brother iPrint&Scan" = 1193539993;
        "Cookie-Editor" = 6446215341;
        "Deliveries" = 290986013;
        "JSON Peep for Safari" = 1458969831;
        "MetaDoctor" = 988250390;
        "Monosnap - screenshot editor" = 540348655;
        "Numbers" = 409203825;
        "Pages" = 409201541;
        "Proton Pass for Safari" = 6502835663;
        "Sink It for Reddit" = 6449873635;
        "Tampermonkey" = 6738342400;
        "Tampermonkey Classic" = 1482490089;
        "The Camelizer" = 1532579087;
    };

    onActivation = {
      cleanup = "zap";
      autoUpdate = true;
      upgrade = true;
    };
  };

  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    user = username;
    autoMigrate = true;
  };
}

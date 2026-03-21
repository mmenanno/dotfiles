{ username, isWorkMachine ? false, ... }:
let
  commonBrews = [
    "coreutils"
    "dotenvx/brew/dotenvx"
    "libyaml"
    "mas"
    "mise"
  ];

  workOnlyBrews = [
    "just"
    "memcached"
    "mysql@8.0"
    "pipenv"
    "pre-commit"
    "pyenv"
    "puma-dev"
    "redis"
  ];

  personalOnlyBrews = [
    "gemini-cli"
    "pandoc"
  ];

  commonCasks = [
    "1password@beta"
    "1password-cli"
    "adguard"
    "claude"
    "claude-code"
    "db-browser-for-sqlite"
    "docker-desktop"
    "git-credential-manager"
    "google-chrome"
    "iterm2"
    "itermbrowserplugin"
    "jordanbaird-ice@beta"
    "logi-options+"
    "logitune"
    "notion"
    "pearcleaner"
    "rectangle"
    "sequel-ace"
    "shottr"
    "slack"
    "the-unarchiver"
    "visual-studio-code"
  ];

  workOnlyCasks = [
    "gather"
    "meetingbar"
  ];

  personalOnlyCasks = [
    "affinity-designer"
    "affinity-photo"
    "affinity-publisher"
    "battle-net"
    "chatgpt"
    "codex"
    "daisydisk"
    "discord"
    "downie"
    "ea"
    "filebot"
    "firefox"
    "gas-mask"
    "ghostty"
    "handbrake-app"
    "imageoptim"
    "kindle-previewer"
    "logseq"
    "lulu"
    "maccy"
    "makemkv"
    "mediainfo"
    "megasync"
    "minecraft"
    "obsidian"
    "plex"
    "postman"
    "proton-drive"
    "proton-mail"
    "proton-mail-bridge"
    "proton-pass"
    "protonvpn"
    "proxyman"
    "quicklook-video"
    "quicklook-json"
    "renpy"
    "scummvm-app"
    "session"
    "signal"
    "steam"
    "syncthing-app"
    "tailscale-app"
    "telegram"
    "textual"
    "torrent-file-editor"
    "transmit"
    "unraid-usb-creator-next"
    "vlc"
    "webpquicklook"
    "whatsapp"
    "zoom"
  ];

  commonMasApps = {
    "1Password for Safari" = 1569813296;
    "Tampermonkey" = 6738342400;
  };

  personalOnlyMasApps = {
    "Brother iPrint&Scan" = 1193539993;
    "Cookie-Editor" = 6446215341;
    "Deliveries" = 290986013;
    "JSON Peep for Safari" = 1458969831;
    "MetaDoctor" = 988250390;
    "Numbers" = 409203825;
    "Pages" = 409201541;
    "Proton Pass for Safari" = 6502835663;
    "Tampermonkey Classic" = 1482490089;
    "The Camelizer" = 1532579087;
  };
in
{
  homebrew = {
    enable = true;
    brews = commonBrews ++ (if isWorkMachine then workOnlyBrews else personalOnlyBrews);
    casks = commonCasks ++ (if isWorkMachine then workOnlyCasks else personalOnlyCasks);
    masApps = commonMasApps // (if isWorkMachine then {} else personalOnlyMasApps);
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

{ lib, username, isWorkMachine ? false, ... }:
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
    "livekit-cli"
    "memcached"
    "mysql@8.4"
    "pipenv"
    "pre-commit"
    "pyenv"
    "puma-dev"
    "redis"
  ];

  personalOnlyBrews = [
    "gemini-cli"
    "pandoc"
    "pgvector"
    "postgresql@17"
    "syncthing"
  ];

  commonCasks = [
    "1password@beta"
    "1password-cli"
    "adguard"
    "claude"
    "claude-code@latest"
    "codex"
    "conductor"
    "db-browser-for-sqlite"
    "docker-desktop"
    "google-chrome"
    "iterm2"
    "itermbrowserplugin"
    "jordanbaird-ice@beta"
    "notion"
    "openlogi"
    "pearcleaner"
    "rectangle"
    "sequel-ace"
    "shottr"
    "the-unarchiver"
    "visual-studio-code"
  ];

  workOnlyCasks = [
    "linear"
    "meetingbar"
    "slack"
    "tuple"
    "wispr-flow"
  ];

  personalOnlyCasks = [
    "affinity-designer"
    "affinity-photo"
    "affinity-publisher"
    "chatgpt"
    "daisydisk"
    "discord"
    "downie"
    "ea"
    "filebot"
    "firefox"
    "imageoptim"
    "lulu"
    "maccy"
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
    "renpy"
    "scummvm-app"
    "signal"
    "steam"
    "switchhosts"
    "syncthing-app"
    "tailscale-app"
    "textual"
    "transmit"
    "unraid-usb-creator"
    "vlc"
    "whatsapp"
    "zoom"
  ];

  commonMasApps = {
    "1Password for Safari" = 1569813296;
    "Tampermonkey" = 6738342400;
  };

  personalOnlyMasApps = {
    "Cookie-Editor" = 6446215341;
    "Deliveries" = 290986013;
    "JSON Peep for Safari" = 1458969831;
    "MetaDoctor" = 988250390;
    "Numbers" = 409203825;
    "Pages" = 409201541;
    "Palworld" = 6503918400;
    "Proton Pass for Safari" = 6502835663;
    "Tampermonkey Classic" = 1482490089;
    "The Camelizer" = 1532579087;
    "Xcode" = 497799835;
  };
in
{
  homebrew = {
    enable = true;
    # Homebrew 6 only loads formulae from trusted third-party taps. Fully
    # qualified brews (dotenvx/brew/dotenvx) are trusted by default; puma-dev
    # is a plain name resolved through this tap, so the tap needs trusting
    taps = lib.optionals isWorkMachine [
      { name = "puma/puma"; trusted = true; }
    ];
    brews = commonBrews ++ (if isWorkMachine then workOnlyBrews else personalOnlyBrews);
    casks = commonCasks ++ (if isWorkMachine then workOnlyCasks else personalOnlyCasks);
    masApps = commonMasApps // (if isWorkMachine then {} else personalOnlyMasApps);
    onActivation = {
      cleanup = "zap";
      autoUpdate = false; # false due to this issue https://github.com/zhaofengli/nix-homebrew/issues/131
      upgrade = true;
      extraEnv = {
        HOMEBREW_NO_ENV_HINTS = "1";
        HOMEBREW_NO_ANALYTICS = "1";
        HOMEBREW_NO_ANALYTICS_MESSAGE_OUTPUT = "1";
        HOMEBREW_NO_UPDATE_REPORT_NEW = "1";
      };
      extraFlags = [ "--quiet" ];
    };
  };

  # postgresql@17 is keg-only, so its client tools (psql, pg_dump) aren't on PATH.
  # Add its stable Homebrew opt/bin declaratively instead of `brew link --force`
  # (stateful, and conflicts with a future postgresql@18). Goes through
  # environment.systemPath -> set-environment -> /etc/zshenv, so it also covers
  # non-interactive shells. Personal-only: postgresql@17 is a personalOnlyBrews entry.
  environment.systemPath = lib.optionals (!isWorkMachine) [
    "/opt/homebrew/opt/postgresql@17/bin"
  ];

  nix-homebrew = {
    enable = true;
    enableRosetta = false;
    user = username;
    autoMigrate = true;
  };
}

{ config, lib, username, isWorkMachine ? false, ... }:
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
    "battle-net"
    "chatgpt"
    "codex"
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
    "webpquicklook"
    "whatsapp"
    "zoom"
  ];

  commonMasApps = {
    "1Password for Safari" = 1569813296;
    "Tampermonkey" = 6738342400;
  };

  # Third-party taps that need explicit trust under Homebrew 6.0 (see
  # system.activationScripts.preActivation below).
  trustedTaps = [ "dotenvx/brew" ] ++ (if isWorkMachine then [ "puma/puma" ] else [ ]);

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
  };
in
{
  homebrew = {
    enable = true;
    brews = commonBrews ++ (if isWorkMachine then workOnlyBrews else personalOnlyBrews);
    casks = commonCasks ++ (if isWorkMachine then workOnlyCasks else personalOnlyCasks);
    masApps = commonMasApps // (if isWorkMachine then {} else personalOnlyMasApps);
    onActivation = {
      # Homebrew 6.0 (June 2026) deprecated the `brew bundle --cleanup` switch in
      # favour of `--force-cleanup` (with `--zap` for zap-style cleanup). The
      # pinned nix-darwin still emits the old `--cleanup --zap` for
      # `cleanup = "zap"` (fix pending in nix-darwin#1789), which prints a
      # deprecation warning on every activation. Until that PR lands we keep
      # `cleanup = "none"` so nix-darwin emits no cleanup flag, and pass the new
      # flags via extraFlags below — equivalent zap cleanup, no warning. Revert to
      # `cleanup = "zap"` (and drop the flags) once #1789 is merged.
      cleanup = "none";
      autoUpdate = false; # false due to this issue https://github.com/zhaofengli/nix-homebrew/issues/131
      upgrade = true;
      extraEnv = {
        HOMEBREW_NO_ENV_HINTS = "1";
        HOMEBREW_NO_ANALYTICS = "1";
        HOMEBREW_NO_ANALYTICS_MESSAGE_OUTPUT = "1";
        HOMEBREW_NO_UPDATE_REPORT_NEW = "1";
      };
      extraFlags = [ "--zap" "--force-cleanup" "--quiet" ];
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
    enableRosetta = true;
    user = username;
    autoMigrate = true;
  };

  # Homebrew 6.0 (June 2026) requires third-party taps to be explicitly trusted
  # before `brew bundle` will load their formulae/casks. nix-darwin has no
  # declarative trust option yet (tracked in nix-darwin#1794, PR nix-darwin#1789
  # adds `homebrew.brews.*.trusted`), so we trust third-party taps here. This runs
  # in `preActivation`, which executes before the homebrew bundle step, and
  # mirrors the bundle's own `sudo --user --set-home` invocation so both resolve
  # the same trust store (~/.homebrew/trust.json; XDG_CONFIG_HOME is not
  # preserved through sudo). Idempotent — remove once PR #1789 lands and switch
  # the relevant brew entries to `{ name = "..."; trusted = true; }`.
  system.activationScripts.preActivation.text = lib.mkAfter ''
    if [ -x ${config.homebrew.prefix}/bin/brew ]; then
      ${lib.concatMapStringsSep "\n" (tap: ''
        sudo --user=${lib.escapeShellArg username} --set-home \
          ${config.homebrew.prefix}/bin/brew trust --tap ${lib.escapeShellArg tap} >/dev/null 2>&1 || true
      '') trustedTaps}
    fi
  '';
}

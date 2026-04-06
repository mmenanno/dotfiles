{ pkgs, lib, isWorkMachine ? false, ... }:
let
  commonPackages = with pkgs; [
    docker
    ejson
    ejson2env
    ffmpeg
    findutils
    fzf
    gh
    git
    git-lfs
    github-mcp-server
    imagemagick
    lazygit
    markdownlint-cli
    mkalias
    openssl
    pkg-config
    rclone
    rsync
    shellcheck
    pay-respects
    watchman
    yq
    zellij
    zoxide
  ];

  workOnlyPackages = with pkgs; [
    awscli2
    graphviz
    librsvg
    pre-commit
    shared-mime-info
    xz
    zstd
  ];

  personalOnlyPackages = with pkgs; [
    audacity
    automake
    autoconf
    cargo
    exiftool
    gmp
    go
    gum
    hugo
    hyperfine
    jdk17
    mariadb
    mkvtoolnix
    mediainfo
    pipx
    pnpm_9
    pylint
    python3
    readline
    ruff
    rustc
    scc
    speedtest-cli
    terminal-notifier
    typescript
    undmg
    wget
    wireguard-go
    wireguard-tools
    x264
    x265
    texliveFull
    unar
    yazi
    yt-dlp
  ];
in
{
  nixpkgs.config.allowUnfree = true;

  # Create symlinks for Audacity to find FFmpeg libraries (personal only)
  system.activationScripts.postActivation.text = if isWorkMachine then "" else lib.mkAfter ''
    echo "Setting up Audacity FFmpeg symlinks..."
    mkdir -p /usr/local/lib/audacity
    for f in ${pkgs.ffmpeg_7.lib}/lib/*.dylib; do
      ln -sf "$f" /usr/local/lib/audacity/
    done
    echo "Audacity FFmpeg symlinks created in /usr/local/lib/audacity/"
  '';

  environment.systemPackages = commonPackages ++ (if isWorkMachine then workOnlyPackages else personalOnlyPackages);
}

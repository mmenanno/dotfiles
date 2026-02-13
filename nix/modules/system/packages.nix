{ pkgs, lib, ... }: {
  nixpkgs.config.allowUnfree = true;

  # Create symlinks for Audacity to find FFmpeg libraries
  system.activationScripts.postActivation.text = lib.mkAfter ''
    echo "Setting up Audacity FFmpeg symlinks..."
    mkdir -p /usr/local/lib/audacity
    for f in ${pkgs.ffmpeg_7.lib}/lib/*.dylib; do
      ln -sf "$f" /usr/local/lib/audacity/
    done
    echo "Audacity FFmpeg symlinks created in /usr/local/lib/audacity/"
  '';

  environment.systemPackages = with pkgs; [
    audacity
    automake
    autoconf
    cargo
    docker
    ejson
    ejson2env
    exiftool
    ffmpeg
    findutils
    fzf
    gh
    git
    git-lfs
    github-mcp-server
    gmp
    go
    gum
    hugo
    hyperfine
    imagemagick
    jdk17
    lazygit
    mariadb
    markdownlint-cli
    mkalias
    mkvtoolnix
    mediainfo
    nodejs
    openssl
    pipx
    pnpm
    pnpm_9
    pylint
    python3
    readline
    rclone
    rsync
    ruff
    rustc
    scc
    shellcheck
    speedtest-cli
    terminal-notifier
    pay-respects
    typescript
    undmg
    watchman
    wget
    wireguard-go
    wireguard-tools
    x264
    x265
    texliveFull
    unar
    yarn
    yazi
    yq
    yt-dlp
    zellij
    zoxide
  ];
}

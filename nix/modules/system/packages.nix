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
    uv
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
    biome
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
    pmtiles
    pnpm_10
    pylint
    python3
    readline
    ruff
    rumdl
    rustc
    scc
    speedtest-cli
    terminal-notifier
    typescript
    undmg
    vips
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

    # Expose Nix's libvips to ruby-vips, which dlopens libvips.42.dylib via FFI.
    # SIP strips DYLD_FALLBACK_LIBRARY_PATH when Ruby's /usr/bin/env shebang execs,
    # so we symlink into /usr/local/lib (an FFI default search dir, SIP-immune) and
    # refresh it on every activation so it self-heals across libvips upgrades.
    echo "Linking Nix libvips into /usr/local/lib for ruby-vips FFI..."
    mkdir -p /usr/local/lib
    for f in ${lib.getLib pkgs.vips}/lib/libvips*.dylib; do
      ln -sf "$f" "/usr/local/lib/$(basename "$f")"
    done
    echo "Nix libvips symlinks created in /usr/local/lib/"
  '';

  environment.systemPackages = commonPackages ++ (if isWorkMachine then workOnlyPackages else personalOnlyPackages);
}

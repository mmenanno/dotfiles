{ config, lib, pkgs, ... }:

{
  # Mise (development environment manager) configuration
  programs.mise = {
    enable = true;
    enableZshIntegration = true;
    package = pkgs.mise;
    globalConfig = {
      tools = {
        python = "latest";
        ruby = "latest";
        node = "lts";
        pnpm = "latest";
        rust = "latest";
      };
      settings = {
        idiomatic_version_file_enable_tools = ["ruby" "python" "node" "nodejs" "rust"];
        auto_install = true;
      };
    };
  };

  # Ensure Ruby LSP can find mise when launched from GUI apps like Cursor.
  # Ruby LSP looks for mise in ~/.local/bin, /opt/homebrew/bin, or /usr/bin.
  # Since mise is installed via Nix in the store, provide a stable symlink.
  home.file = {
    ".local/bin/mise".source = "${pkgs.mise}/bin/mise";
  };
}

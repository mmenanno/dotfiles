{ pkgs, ... }:

{
  # Mise (development environment manager) configuration
  programs.mise = {
    enable = true;
    # Disable auto-integration to use lazy loading with shims instead
    enableZshIntegration = false;
    package = pkgs.mise;
    globalConfig = {
      tools = {
        python = "latest";
        ruby = "latest";
        node = "latest";
        pnpm = "latest";
        rust = "latest";
      };
      settings = {
        idiomatic_version_file_enable_tools = ["ruby" "python" "node" "nodejs" "rust"];
        auto_install = true;
        # Disable tools that are managed by Nix instead of mise
        # This prevents mise from checking/installing these on every shell startup
        disable_tools = ["node" "pnpm" "rust"];
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

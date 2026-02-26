{ mkHomebrewWrapper, ... }:

{
  # Mise (development environment manager) configuration
  # Binary installed via Homebrew for faster updates; config managed by Home Manager
  programs.mise = {
    enable = true;
    # Disable auto-integration to use lazy loading with shims instead
    enableZshIntegration = false;
    package = mkHomebrewWrapper {
      name = "mise";
      homebrewBinary = "mise";
    };
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
}

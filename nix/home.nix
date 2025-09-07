{ config, pkgs, self, inputs, ... }:

{
  imports = [
    ./modules/gh.nix
    ./modules/git.nix
    ./modules/ruby.nix
    ./modules/rails-mcp.nix
    ./modules/ssh.nix
    ./modules/zsh.nix
    ./modules/starship.nix
    ./modules/home-manager-system-defaults.nix
    ./modules/cursor.nix
    ./modules/mise.nix
    ./modules/onepassword.nix
    ./modules/claude.nix
    ./modules/codex.nix
  ];

  # home.username and home.homeDirectory are now set in flake.nix

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "24.05";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}

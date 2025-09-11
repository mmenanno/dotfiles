 { self, username, homeDirectory,... }:

{
  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";
  nix.settings.download-buffer-size = 268435456; # 256 MiB
  nix.settings.auto-optimise-store = true;
  nix.settings.extra-substituters = [
    "https://cache.nixos.org/"
    "https://nix-community.cachix.org"
  ];
  nix.settings.extra-trusted-public-keys = [
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  ];

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true;  # default shell on catalina

  # Set Git commit hash for darwin-version.
  system.configurationRevision = self.rev or self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  system.stateVersion = 5;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Use Touch ID to authenticate sudo
  security.pam.services.sudo_local.touchIdAuth = true;

  nix.gc = {
    automatic = true;
    interval = { Weekday = 0; Hour = 2; Minute = 0; };
    options = "--delete-older-than 30d";
  };

  users.users.${username} = {
    name = username;
    home = homeDirectory;
  };

  # Set the primary user for nix-darwin user-specific configurations
  system.primaryUser = username;
}

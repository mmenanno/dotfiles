 { self, username, homeDirectory,... }:

{
  # Nix configuration
  nix = {
    # Necessary for using flakes on this system.
    settings = {
      experimental-features = "nix-command flakes";
      download-buffer-size = 268435456; # 256 MiB
      extra-substituters = [
        "https://cache.nixos.org/"
        "https://nix-community.cachix.org"
      ];
      extra-trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };

    # Use supported optimise service instead of store-level flag
    optimise.automatic = true;

    gc = {
      automatic = true;
      interval = { Weekday = 0; Hour = 2; Minute = 0; };
      options = "--delete-older-than 30d";
    };
  };

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true;  # default shell on catalina

  # System configuration
  system = {
    # Set Git commit hash for darwin-version.
    configurationRevision = self.rev or self.dirtyRev or null;

    # Used for backwards compatibility, please read the changelog before changing.
    stateVersion = 5;

    # Set the primary user for nix-darwin user-specific configurations
    primaryUser = username;
  };

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Use Touch ID to authenticate sudo
  security.pam.services.sudo_local.touchIdAuth = true;

  users.users.${username} = {
    name = username;
    home = homeDirectory;
  };
}

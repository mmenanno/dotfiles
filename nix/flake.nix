{
  description = "Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew, home-manager }:
    let
      # Import shared utilities
      lib = import ./modules/lib.nix;
      inherit (lib) getEnvOrFallback;

      # Environment-based username with fallback using consistent pattern
      username = getEnvOrFallback "NIX_FULL_NAME" "bootstrap-user" "placeholder-user";
      homeDirectory = "/Users/${username}";
      homeManagerConfig = {
        inherit username homeDirectory;
      };
      commonConfig = {
        inherit username homeDirectory;
        inherit inputs self;
      };
    in {
    darwinConfigurations."macbook_setup" = nix-darwin.lib.darwinSystem {
      modules = [
        ./modules/base-configuration.nix
        ./modules/packages.nix
        ./modules/homebrew.nix
        ./modules/pwa-apps.nix # run before system-defaults.nix to ensure chrome pwa apps exist for dock
        ./modules/system-defaults.nix
        ./modules/rectangle.nix
        ./modules/tailscale.nix
        ./modules/fonts.nix
        ./modules/applications-alias.nix
        ./modules/autoclick.nix
        nix-homebrew.darwinModules.nix-homebrew
        home-manager.darwinModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.${username} = {
              imports = [ ./home.nix ];
              home = homeManagerConfig;
            };
          };
        }
      ];
      specialArgs = commonConfig;
    };

    # Expose the package set under a standard flake output to avoid warnings.
    legacyPackages.aarch64-darwin = self.darwinConfigurations."macbook_setup".pkgs;

    # Provide a formatter for `nix fmt`
    formatter.aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixfmt;
  };
}

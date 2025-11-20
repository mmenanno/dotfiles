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

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew, home-manager, ... }:
    let
      # Import shared utilities
      lib = import ./modules/lib.nix;
      inherit (lib) getEnvOrFallback;

      moduleIndex = import ./modules/default.nix;

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
      modules =
        moduleIndex.systemModules
        ++ [
          nix-homebrew.darwinModules.nix-homebrew
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = commonConfig // { dotlib = lib; };
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

    # Dev shell for local linting and formatting
    devShells.aarch64-darwin.default =
      let
        pkgs = nixpkgs.legacyPackages.aarch64-darwin;
      in pkgs.mkShell {
        packages = [
          pkgs.nixfmt
          pkgs.shellcheck
          pkgs.nodePackages.markdownlint-cli2
        ];
      };

    # Expose module sets for reuse
    darwinModules.default = moduleIndex.systemModules;
    homeManagerModules.default = moduleIndex.homeModules;
  };
}

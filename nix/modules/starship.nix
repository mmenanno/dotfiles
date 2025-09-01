{ pkgs, lib, ... }:

let
  # Load the complete nerd-font preset and merge with our customizations
  nerdFontPreset = builtins.fromTOML (builtins.readFile (pkgs.fetchurl {
    url = "https://starship.rs/presets/toml/nerd-font-symbols.toml";
    hash = "sha256-eVWWFuMC6fGTQAtLSVg++G7Gw9wU4VO9rQCVxXzE2xc=";
  }));

  # Our custom overrides
  customSettings = {
    add_newline = false;

    character = {
      success_symbol = "[➜](bold green)";
      error_symbol = "[➜](bold red)";
    };

    directory = {
      truncate_to_repo = true;
    };

    cmd_duration = {
      disabled = true;
    };
  };

  # Merge preset with our customizations
  starshipSettings = lib.recursiveUpdate nerdFontPreset customSettings;
in
{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = starshipSettings;
  };
}

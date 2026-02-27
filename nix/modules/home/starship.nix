{ pkgs, lib, ... }:

let
  # Load the preset bundled with the installed starship package
  nerdFontPreset = builtins.fromTOML (
    builtins.readFile "${pkgs.starship}/share/starship/presets/nerd-font-symbols.toml"
  );

  # Our custom overrides
  customSettings = {
    add_newline = false;

    # Increase timeout for slow git operations
    command_timeout = 2000;  # 2 seconds (default is 500ms)

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

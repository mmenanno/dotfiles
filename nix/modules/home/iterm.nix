_:
# Scope: Home (Home Manager). iTerm2 profile settings as a Dynamic Profile,
# which iTerm reads itself whenever it starts, so it works even on a fresh Mac
# where iTerm's own preferences don't exist yet. It inherits everything from
# the "Default" profile and is made the default in system-defaults.nix.
{
  home.file."Library/Application Support/iTerm2/DynamicProfiles/nix.json".text = builtins.toJSON {
    Profiles = [
      {
        Name = "Nix";
        Guid = "nix-managed-profile";
        "Dynamic Profile Parent Name" = "Default";
        "Normal Font" = "MesloLGSNFM-Regular 11";
        "Non Ascii Font" = "MesloLGSNFM-Regular 11";
        # Open new sessions in the previous session's directory
        "Custom Directory" = "Recycle";
      }
    ];
  };
}

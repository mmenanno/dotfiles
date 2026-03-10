{ inputs, isWorkMachine ? false, ... }:

let
  moduleIndex = import ./modules/default.nix;
  homeModules = if isWorkMachine then moduleIndex.workHomeModules else moduleIndex.homeModules;
in
{
  imports = homeModules ++ [
    inputs.nix-index-database.homeModules.nix-index
  ];

  home.stateVersion = "25.05";
  programs.home-manager.enable = true;
}

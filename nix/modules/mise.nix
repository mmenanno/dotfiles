{ config, lib, pkgs, ... }:

{
  # Mise (development environment manager) configuration
  programs.mise = {
    enable = true;
    enableZshIntegration = true;
    package = pkgs.mise;
    globalConfig = {
      tools = {
        python = "latest";
        ruby = "latest";
      };
      settings = {
        idiomatic_version_file_enable_tools = ["ruby"];
      };
    };
  };
}

{ config, lib, pkgs, username, ... }:

{
  security.sudo = {
    enable = true;
    extraRules = [
      {
        users = [ username ];
        commands = [
          {
            command = "/run/current-system/sw/bin/darwin-rebuild";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
  };
}



{ config, lib, pkgs, username, ... }:

{
  # Allow passwordless sudo for darwin-rebuild for the configured user
  environment.etc."sudoers.d/darwin-rebuild" = {
    text = ''
      ${username} ALL=(root) NOPASSWD: /run/current-system/sw/bin/darwin-rebuild
    '';
    mode = "0440";
    user = "root";
    group = "wheel";
  };
}



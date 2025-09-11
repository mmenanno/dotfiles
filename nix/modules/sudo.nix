{ config, lib, pkgs, username, ... }:

{
  # Allow passwordless sudo for darwin-rebuild for the configured user
  environment.etc."sudoers.d/darwin-rebuild" = {
    text = ''
      Defaults:${username} env_keep += "NIX_*"
      ${username} ALL=(root) NOPASSWD: /run/current-system/sw/bin/darwin-rebuild
    '';
  };
}



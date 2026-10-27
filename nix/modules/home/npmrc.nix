{ secretFile, ... }:
{
  # npm expands ${SIERRA_NPM_TOKEN} from the environment, so the token stays
  # out of the Nix store and this file
  home.file.".npmrc".text = ''
    //packages.sierra.ai/:_authToken=user:''${SIERRA_NPM_TOKEN}
  '';

  programs.zsh.envExtra = ''
    [[ -r ${secretFile "sierra-auth-token"} ]] && export SIERRA_NPM_TOKEN="$(<${secretFile "sierra-auth-token"})"
  '';
}

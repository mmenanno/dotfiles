{ dotlib, ... }:
let
  sierraToken = dotlib.getEnvOrFallback "NIX_SIERRA_AUTH_TOKEN" "bootstrap-token" "placeholder-token";
in
{
  home.file.".npmrc".text = ''
    //packages.sierra.ai/:_authToken=user:${sierraToken}
  '';
}

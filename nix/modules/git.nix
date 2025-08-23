{ ... }:
let
  # Import shared utilities
  lib = import ./lib.nix;
  inherit (lib) getEnvOrFallback;
  
  # Bootstrap mode detection
  isBootstrap = builtins.getEnv "NIX_BOOTSTRAP_MODE" == "1";
  
  # Main configuration
  personalEmail = getEnvOrFallback "NIX_PERSONAL_EMAIL" "bootstrap@example.com" "placeholder+github@example.com";
  githubUser = getEnvOrFallback "NIX_GITHUB_USER" "bootstrap-user" "placeholder-user";
  signingKey = getEnvOrFallback "NIX_SIGNING_KEY" "bootstrap-key" "ssh-ed25519 PLACEHOLDER_SIGNING_KEY_CHANGE_ME";
  
  # Private configuration
  privateEmail = getEnvOrFallback "NIX_PRIVATE_EMAIL" "bootstrap-private@example.com" "placeholder-private@example.com";
  privateUser = getEnvOrFallback "NIX_PRIVATE_USER" "bootstrap-private-user" "placeholder-private-user";
  privateSigningKey = getEnvOrFallback "NIX_PRIVATE_SIGNING_KEY" "bootstrap-private-key" "ssh-ed25519 PLACEHOLDER_PRIVATE_SIGNING_KEY_CHANGE_ME";
  privateGitDir = getEnvOrFallback "NIX_PRIVATE_GITDIR" "~/dev/bootstrap/" "~/dev/placeholder-private/";
  
  # Git services
  forgejoDomain = getEnvOrFallback "NIX_FORGEJO_DOMAIN" "https://git.example.com" "https://git.placeholder.com";
in
{
  programs.git = {
    enable = true;
    userName = githubUser;
    userEmail = personalEmail;
    signing = {
      key = signingKey;
      signByDefault = true;
    };
    extraConfig = {
      push.autoSetupRemote = true;
      gpg = {
        format = "ssh";
        ssh.program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
      };
      credential = {
        "${forgejoDomain}" = {
          provider = "generic";
        } // (if isBootstrap then {} else {});  # Conditional personal forge config
        helper = "/usr/local/share/gcm-core/git-credential-manager";
        "https://dev.azure.com" = {
          useHttpPath = true;
        };
      };
      init.defaultBranch = "main";
      tag.gpgsign = true;
    };

    includes = [{
      condition = "gitdir:${privateGitDir}";
      contents.user = {
        email = privateEmail;
        name = privateUser;
        signingKey = privateSigningKey;
      };
    }];
  };
}

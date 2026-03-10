{ dotlib, sharedIdentity, isWorkMachine ? false, lib, ... }:
# Scope: Home (Home Manager). Configures Git identity, signing, and defaults.
let
  inherit (dotlib) getEnvOrFallback getPersonalEnvOrFallback;
  getPersonalEnv = getPersonalEnvOrFallback isWorkMachine;
  inherit (sharedIdentity) personalEmail privateEmail privateUser;

  # Main configuration
  githubUser = getEnvOrFallback "NIX_GITHUB_USER" "bootstrap-user" "placeholder-user";
  signingKey = getEnvOrFallback "NIX_SIGNING_KEY" "bootstrap-key" "ssh-ed25519 PLACEHOLDER_SIGNING_KEY_CHANGE_ME";

  # Private configuration
  privateSigningKey = getPersonalEnv "NIX_PRIVATE_SIGNING_KEY" "bootstrap-private-key" "ssh-ed25519 PLACEHOLDER_PRIVATE_SIGNING_KEY_CHANGE_ME";
  privateGitDir = getPersonalEnv "NIX_PRIVATE_GITDIR" "~/dev/bootstrap/" "~/dev/placeholder-private/";

  # Git services
  forgejoDomain = getPersonalEnv "NIX_FORGEJO_DOMAIN" "https://git.example.com" "https://git.placeholder.com";
  levForgejoDomain = getPersonalEnv "NIX_LEV_FORGEJO_DOMAIN" "https://git.lev.example.com" "https://git.lev.placeholder.com";
in
{
  programs.git = {
    enable = true;
    signing = {
      key = signingKey;
      signByDefault = true;
    };

    # Git LFS configuration
    lfs = {
      enable = true;
    };

    # Global gitignore patterns
    ignores = [
      # OS files
      ".DS_Store"
      "Thumbs.db"

      # Editor files
      ".vscode/"
      ".idea/"
      "*.swp"
      "*.swo"
      "*~"

      # Environment files
      ".env"
      ".env.local"

      # Dependencies
      "node_modules/"
      ".pnp/"
      ".pnp.js"

      # Build outputs
      "dist/"
      "build/"
      "*.log"

      # Misc
      ".direnv/"
      ".mise.toml.local"

      # Nix build artifacts
      "result"
      "result-*"

      # AI tool settings
      "**/.claude/settings.local.json"
    ];

    settings = {
      alias = {
        sw = "!f() { case \"$1\" in *:*) gh pr checkout \"$@\" ;; *) git switch \"$@\" ;; esac; }; f";
      };
      user = {
        name = githubUser;
        email = personalEmail;
      };
      push.autoSetupRemote = true;
      gpg = {
        format = "ssh";
        ssh = {
          program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
          allowedSignersFile = "~/.ssh/allowed_signers";
        };
      };
      credential = {
        helper = "/usr/local/share/gcm-core/git-credential-manager";
        "https://dev.azure.com" = {
          useHttpPath = true;
        };
      } // lib.optionalAttrs (!isWorkMachine) {
        "${forgejoDomain}" = {
          provider = "generic";
        };
        "${levForgejoDomain}" = {
          provider = "generic";
        };
      };
      init.defaultBranch = "main";
      tag.gpgsign = true;
      core.editor = "code --wait";

      # Git LFS locking support
      lfs.locksverify = true;

      # URL rewrites for faster cloning (use SSH instead of HTTPS)
      url = {
        "git@github.com:" = {
          insteadOf = "https://github.com/";
        };
      };
    };

    includes = if isWorkMachine then [] else [{
      condition = "gitdir:${privateGitDir}";
      contents.user = {
        email = privateEmail;
        name = privateUser;
        signingKey = privateSigningKey;
      };
    }];
  };

  # Delta - beautiful diffs with syntax highlighting
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      features = "line-numbers decorations";
      navigate = true;
      light = false;
      side-by-side = true;
      line-numbers-left-format = "";
      line-numbers-right-format = "│ ";
      syntax-theme = "TwoDark";

      decorations = {
        commit-decoration-style = "bold yellow box ul";
        file-style = "bold yellow ul";
        file-decoration-style = "none";
      };
    };
  };

  # SSH allowed signers file for commit signature verification
  home.file.".ssh/allowed_signers".text = ''
    ${personalEmail} ${signingKey}
  '' + (if isWorkMachine then "" else ''
    ${privateEmail} ${privateSigningKey}
  '');
}

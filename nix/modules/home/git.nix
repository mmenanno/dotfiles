{ dotlib, ... }:
# Scope: Home (Home Manager). Configures Git identity, signing, and defaults.
let
  inherit (dotlib) getEnvOrFallback;

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
  levForgejoDomain = getEnvOrFallback "NIX_LEV_FORGEJO_DOMAIN" "https://git.lev.example.com" "https://git.lev.placeholder.com";
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
        "${forgejoDomain}" = {
          provider = "generic";
        } // (if isBootstrap then {} else {});  # Conditional personal forge config
        "${levForgejoDomain}" = {
          provider = "generic";
        } // (if isBootstrap then {} else {});  # Conditional Lev forge config
        helper = "/usr/local/share/gcm-core/git-credential-manager";
        "https://dev.azure.com" = {
          useHttpPath = true;
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

    includes = [{
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
    ${privateEmail} ${privateSigningKey}
  '';
}

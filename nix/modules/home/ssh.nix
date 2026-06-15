{ config, lib, dotlib, sharedIdentity, isWorkMachine ? false, ... }:
# Scope: Home (Home Manager). Configures SSH hosts and 1Password agent usage.

let
  inherit (dotlib) getEnvOrFallback getPersonalEnvOrFallback;
  inherit (config.home) username;
  inherit (sharedIdentity) personalEmail privateEmail privateUser;

  getPersonalEnv = getPersonalEnvOrFallback isWorkMachine;

  sshDir = "${config.home.homeDirectory}/.ssh";
  laptopName = getEnvOrFallback "NIX_LAPTOP_NAME" "bootstrap-laptop" "placeholder-laptop";
  macbook_hostname = "${username}@${laptopName}";

  # Environment-based IPs with bootstrap fallbacks
  ips = {
    main_server = getEnvOrFallback "NIX_SERVER_IP_MAIN" "192.168.x.x" "192.168.x.x";
    nvm_server = getEnvOrFallback "NIX_SERVER_IP_NVM" "192.168.y.y" "192.168.y.y";
  };

  # Server and user names from environment
  mainServerName = getEnvOrFallback "NIX_SERVER_NAME_L" "bootstrap-server" "placeholder-server";
  nvmServerName = getEnvOrFallback "NIX_SERVER_NVM_NAME" "bootstrap-vm" "placeholder-vm";
  privateUserShort = getPersonalEnv "NIX_PRIVATE_USER_SHORT" "bootstrap-short" "placeholder-short";

  # Identity file names from environment
  mainServerKeyFile = getEnvOrFallback "NIX_SSH_MAIN_SERVER_KEYFILE" "bootstrap-main" "placeholder-main";
  nvmServerKeyFile = getEnvOrFallback "NIX_SSH_NVM_SERVER_KEYFILE" "bootstrap-nvm" "placeholder-nvm";
  mainGithubKeyFile = getEnvOrFallback "NIX_SSH_MAIN_GITHUB_KEYFILE" "bootstrap-main-github" "placeholder-main-github";
  privateGithubKeyFile = getPersonalEnv "NIX_SSH_PRIVATE_GITHUB_KEYFILE" "bootstrap-private-github" "placeholder-private-github";

  # SSH public keys from environment
  mainServerKey = getEnvOrFallback "NIX_SSH_MAIN_SERVER_KEY" "ssh-ed25519 BOOTSTRAP_MAIN_SERVER_KEY" "ssh-ed25519 PLACEHOLDER_MAIN_SERVER_KEY_CHANGE_ME";
  nvmServerKey = getEnvOrFallback "NIX_SSH_NVM_SERVER_KEY" "ssh-ed25519 BOOTSTRAP_NVM_SERVER_KEY" "ssh-ed25519 PLACEHOLDER_NVM_SERVER_KEY_CHANGE_ME";
  mainGithubKey = getEnvOrFallback "NIX_SSH_MAIN_GITHUB_KEY" "ssh-ed25519 BOOTSTRAP_MAIN_GITHUB_KEY" "ssh-ed25519 PLACEHOLDER_MAIN_GITHUB_KEY_CHANGE_ME";
  privateGithubKey = getPersonalEnv "NIX_SSH_PRIVATE_GITHUB_KEY" "ssh-ed25519 BOOTSTRAP_PRIVATE_GITHUB_KEY" "ssh-ed25519 PLACEHOLDER_PRIVATE_GITHUB_KEY_CHANGE_ME";

  # Kelsey's Mac from environment
  kLaptop = getPersonalEnv "NIX_K_LAPTOP" "bootstrap-k-laptop" "placeholder-k-laptop";
  kHostname = getPersonalEnv "NIX_K_HOSTNAME" "192.168.x.x" "192.168.x.x";
  kUsername = getPersonalEnv "NIX_K_USERNAME" "bootstrap-k-user" "placeholder-k-user";

  # Forgejo domains from environment
  forgejoDomainFull = getPersonalEnv "NIX_FORGEJO_DOMAIN" "https://git.example.com" "https://git.placeholder.com";
  levForgejoDomainFull = getPersonalEnv "NIX_LEV_FORGEJO_DOMAIN" "https://git.lev.example.com" "https://git.lev.placeholder.com";

  # Extract hostname from full URL (remove https://)
  forgejoDomain = builtins.replaceStrings ["https://" "http://"] ["" ""] forgejoDomainFull;
  levForgejoDomain = builtins.replaceStrings ["https://" "http://"] ["" ""] levForgejoDomainFull;

  # Common configurations
  common = {
    private = {
      user = privateUser;
      # OpenSSH directives shared by interactive private-host blocks
      sessionDirectives = {
        RequestTTY = "force";
      };
    };
  };

  with_bash_login_command = "&& exec bash --login";

  # Use a stable no-spaces symlink for the 1Password agent socket to avoid
  # quoting/subshell issues in ssh config
  onePasswordAgentSymlink = "${config.home.homeDirectory}/.ssh/1password-agent.sock";

  # Domain + key sourced from 1Password (Nix/Work); staging derived from prod.
  bastionDomain = getEnvOrFallback "NIX_BASTION_DOMAIN" "bastion.bootstrap.invalid" "bastion.placeholder.invalid";
  bastionKey = getEnvOrFallback "NIX_SSH_BABYLIST_BASTION_KEY" "ssh-ed25519 BOOTSTRAP_BASTION_KEY" "ssh-ed25519 PLACEHOLDER_BASTION_KEY_CHANGE_ME";
  bastionKeyFile = "babylist";
  bastionStageDomain = builtins.replaceStrings [ "-prod." ] [ "-stage." ] bastionDomain;
  bastionConfigured = bastionDomain != "bastion.placeholder.invalid" && bastionDomain != "bastion.bootstrap.invalid";

in
{
  programs.ssh =
    let

      # Helper for NVM server with remote commands
      mkNvmBlock = suffix: remoteCmd: {
        "${nvmServerName}${suffix}" = {
          HostName = ips.nvm_server;
          User = common.private.user;
          IdentityFile = "~/.ssh/${nvmServerKeyFile}";
          RemoteCommand = "${remoteCmd} ${with_bash_login_command}";
        } // common.private.sessionDirectives;
      };

      # Base server blocks
      baseBlocks = {
        "${mainServerName}" = {
          HostName = ips.main_server;
          User = "root";
          Port = 8822;
          IdentityFile = "~/.ssh/${mainServerKeyFile}";
        };
      } // (if mainServerName != nvmServerName then {
        "${nvmServerName}" = {
          HostName = ips.nvm_server;
          User = common.private.user;
          IdentityFile = "~/.ssh/${nvmServerKeyFile}";
        };
      } else {});

      # NVM-specific blocks (only if configured)
      nvmBlocks = if ips.nvm_server != "192.168.y.y" then
        mkNvmBlock "-up" "cd /mnt/torrents/complete-seed/${privateUser}/" //
        mkNvmBlock "-down" "cd /mnt/unmanic/staging"
      else {};

      # Personal-only SSH hosts (servers, private GitHub, Forgejo)
      personalBlocks = baseBlocks // nvmBlocks // {
        "github.${privateUserShort}" = {
          HostName = "github.com";
          IdentityFile = "~/.ssh/${privateGithubKeyFile}";
        };
        "${forgejoDomain}" = {
          HostName = forgejoDomain;
          IdentityFile = "~/.ssh/${mainGithubKeyFile}";
        };
        "${levForgejoDomain}" = {
          HostName = levForgejoDomain;
          IdentityFile = "~/.ssh/${mainGithubKeyFile}";
        };
        "${kLaptop}" = {
          HostName = kHostname;
          User = kUsername;
          IdentityFile = "~/.ssh/${mainGithubKeyFile}";
        };
      };

      # Bastion sets "IdentitiesOnly no" so the agent-held key is offered (the
      # global "*" block below imposes "yes", which makes Net::SSH keys_only
      # offer 0 keys). These blocks precede "*" in the rendered config, so
      # SSH's first-match-wins selects "no" for the bastion hosts.
      bastionBlocks = lib.optionalAttrs bastionConfigured ({
        "${bastionDomain}" = {
          HostName = bastionDomain;
          User = "deploy";
          IdentityFile = "~/.ssh/${bastionKeyFile}";
          IdentitiesOnly = "no";
        };
      } // lib.optionalAttrs (bastionStageDomain != bastionDomain) {
        "${bastionStageDomain}" = {
          HostName = bastionStageDomain;
          User = "deploy";
          IdentityFile = "~/.ssh/${bastionKeyFile}";
          IdentitiesOnly = "no";
        };
      });

    in {
      enable = true;
      enableDefaultConfig = false;
      settings = {
        "*" = {
          IdentityAgent = onePasswordAgentSymlink;
          IdentitiesOnly = true;
        };
        "github.com" = {
          HostName = "github.com";
          IdentityFile = "~/.ssh/${mainGithubKeyFile}";
        };
      } // bastionBlocks // lib.optionalAttrs (!isWorkMachine) personalBlocks;
    };

  home.file = {
    "${sshDir}/${mainGithubKeyFile}.pub".text = "${mainGithubKey} ${personalEmail}";
  } // lib.optionalAttrs bastionConfigured {
    "${sshDir}/${bastionKeyFile}.pub".text = bastionKey;
  } // lib.optionalAttrs (!isWorkMachine) {
    "${sshDir}/${mainServerKeyFile}.pub".text = "${mainServerKey} ${macbook_hostname}";
    "${sshDir}/${nvmServerKeyFile}.pub".text = "${nvmServerKey} ${macbook_hostname}";
    "${sshDir}/${privateGithubKeyFile}.pub".text = "${privateGithubKey} ${privateEmail}";
  };
}

{ config, dotlib, ... }:
# Scope: Home (Home Manager). Configures SSH hosts and 1Password agent usage.

let
  inherit (dotlib) getEnvOrFallback;

  sshDir = "${config.home.homeDirectory}/.ssh";
  username = config.home.username;
  laptopName = getEnvOrFallback "NIX_LAPTOP_NAME" "bootstrap-laptop" "placeholder-laptop";
  macbook_hostname = "${username}@${laptopName}";

  # Environment-based IPs with bootstrap fallbacks
  ips = {
    main_server = getEnvOrFallback "NIX_SERVER_IP_MAIN" "192.168.x.x" "192.168.x.x";
    nvm_server = getEnvOrFallback "NIX_SERVER_IP_NVM" "192.168.y.y" "192.168.y.y";
  };

  # Environment-based configurations
  personalEmail = getEnvOrFallback "NIX_PERSONAL_EMAIL" "bootstrap@example.com" "placeholder@example.com";
  privateEmail = getEnvOrFallback "NIX_PRIVATE_EMAIL" "bootstrap-alt@example.com" "placeholder-alt@example.com";

  # Server and user names from environment
  mainServerName = getEnvOrFallback "NIX_SERVER_NAME_L" "bootstrap-server" "placeholder-server";
  nvmServerName = getEnvOrFallback "NIX_SERVER_NVM_NAME" "bootstrap-vm" "placeholder-vm";
  privateUser = getEnvOrFallback "NIX_PRIVATE_USER" "bootstrap-user" "placeholder-user";
  privateUserShort = getEnvOrFallback "NIX_PRIVATE_USER_SHORT" "bootstrap-short" "placeholder-short";

  # Identity file names from environment
  mainServerKeyFile = getEnvOrFallback "NIX_SSH_MAIN_SERVER_KEYFILE" "bootstrap-main" "placeholder-main";
  nvmServerKeyFile = getEnvOrFallback "NIX_SSH_NVM_SERVER_KEYFILE" "bootstrap-nvm" "placeholder-nvm";
  mainGithubKeyFile = getEnvOrFallback "NIX_SSH_MAIN_GITHUB_KEYFILE" "bootstrap-main-github" "placeholder-main-github";
  privateGithubKeyFile = getEnvOrFallback "NIX_SSH_PRIVATE_GITHUB_KEYFILE" "bootstrap-private-github" "placeholder-private-github";

  # SSH public keys from environment
  mainServerKey = getEnvOrFallback "NIX_SSH_MAIN_SERVER_KEY" "ssh-ed25519 BOOTSTRAP_MAIN_SERVER_KEY" "ssh-ed25519 PLACEHOLDER_MAIN_SERVER_KEY_CHANGE_ME";
  nvmServerKey = getEnvOrFallback "NIX_SSH_NVM_SERVER_KEY" "ssh-ed25519 BOOTSTRAP_NVM_SERVER_KEY" "ssh-ed25519 PLACEHOLDER_NVM_SERVER_KEY_CHANGE_ME";
  mainGithubKey = getEnvOrFallback "NIX_SSH_MAIN_GITHUB_KEY" "ssh-ed25519 BOOTSTRAP_MAIN_GITHUB_KEY" "ssh-ed25519 PLACEHOLDER_MAIN_GITHUB_KEY_CHANGE_ME";
  privateGithubKey = getEnvOrFallback "NIX_SSH_PRIVATE_GITHUB_KEY" "ssh-ed25519 BOOTSTRAP_PRIVATE_GITHUB_KEY" "ssh-ed25519 PLACEHOLDER_PRIVATE_GITHUB_KEY_CHANGE_ME";

  # Common configurations
  common = {
    private = {
      user = privateUser;
      extraOptions = {
        RequestTTY = "force";
      };
    };
  };

  with_bash_login_command = "&& exec bash --login";

  # 1Password agent socket path file (from onepassword.nix)
  onePasswordAgentPath = "${config.home.homeDirectory}/.config/op/agent-socket";
  onePasswordAgent = "\"$(cat ${onePasswordAgentPath} 2>/dev/null || echo \"${config.home.homeDirectory}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\")\"";

in
{
  programs.ssh =
    let

      # Helper for NVM server with remote commands
      mkNvmBlock = suffix: remoteCmd: {
        "${nvmServerName}${suffix}" = {
          hostname = ips.nvm_server;
          inherit (common.private) user;
          identityFile = "~/.ssh/${nvmServerKeyFile}";
          extraOptions = common.private.extraOptions // {
            RemoteCommand = "${remoteCmd} ${with_bash_login_command}";
          };
        };
      };

      # Base server blocks
      baseBlocks = {
        "${mainServerName}" = {
          hostname = ips.main_server;
          user = "root";
          port = 8822;
          identityFile = "~/.ssh/${mainServerKeyFile}";
        };
      } // (if mainServerName != nvmServerName then {
        "${nvmServerName}" = {
          hostname = ips.nvm_server;
          inherit (common.private) user;
          identityFile = "~/.ssh/${nvmServerKeyFile}";
        };
      } else {});

      # NVM-specific blocks (only if configured)
      nvmBlocks = if ips.nvm_server != "192.168.y.y" then
        mkNvmBlock "-up" "cd /mnt/torrents/complete-seed/${privateUser}/" //
        mkNvmBlock "-down" "cd /mnt/unmanic/staging"
      else {};

    in {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks = baseBlocks // nvmBlocks // {
        "*" = {
          identityAgent = onePasswordAgent;
          identitiesOnly = true;
        };
        "github.com" = {
          hostname = "github.com";
          identityFile = "~/.ssh/${mainGithubKeyFile}";
        };
        "github.${privateUserShort}" = {
          hostname = "github.com";
          identityFile = "~/.ssh/${privateGithubKeyFile}";
        };
      };
    };

  home.file = {
    "${sshDir}/${mainServerKeyFile}.pub".text = "${mainServerKey} ${macbook_hostname}";
    "${sshDir}/${nvmServerKeyFile}.pub".text = "${nvmServerKey} ${macbook_hostname}";
    "${sshDir}/${mainGithubKeyFile}.pub".text = "${mainGithubKey} ${personalEmail}";
    "${sshDir}/${privateGithubKeyFile}.pub".text = "${privateGithubKey} ${privateEmail}";
  };
}

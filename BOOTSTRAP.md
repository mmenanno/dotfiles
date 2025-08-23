# Bootstrap Guide

This dotfiles configuration supports both fresh system setup and ongoing management with 1Password integration.

## Fresh System Setup

On a fresh macOS system, the configuration will automatically detect that 1Password CLI is not available and run in bootstrap mode:

```bash
git clone https://github.com/mmenanno/dotfiles.git
cd dotfiles
nixup  # This will run in bootstrap mode automatically
```

Bootstrap mode provides safe fallback values for:

- Email addresses (uses placeholder values)
- Server IP addresses (uses generic ranges)
- Personal configuration (uses safe defaults)

## After Bootstrap

Once the bootstrap is complete:

1. **Install and configure 1Password**
   - Launch 1Password app and sign in
   - Enable CLI integration: 1Password → Settings → Developer → Command Line Interface

2. **Sign into 1Password CLI**

   ```bash
   op signin
   ```

3. **Create required 1Password items**

## Required 1Password Items

Create these items in your 1Password vault before running nixup:

### Nix/MainID

- `github_email`: Your GitHub email address
- `github_user`: Your GitHub username
- `signing_key`: Your SSH signing key
- `ssh_key`: Your SSH public key
- `github_keyfile`: Your main GitHub SSH keyfile name
- `laptop_name`: Your laptop hostname
- `name_full`: Your full username

### Nix/PrivateID (for alternate git config)

- `ssh_email`: Your alternate SSH email address
- `user`: Your alternate username (for SSH connections)
- `user_short`: Your alternate short username
- `signing_key`: Your alternate SSH signing key
- `ssh_key`: Your alternate SSH public key
- `github_keyfile`: Your alternate GitHub SSH keyfile name
- `gitdir`: Git directory path for alternate config

### Nix/SSH (for server connections)

- `unraid_key`: Your main server SSH public key
- `nvm_key`: Your NVM server SSH public key

### Nix/Git Config

- `forgejo_domain`: Your Forgejo instance URL

### Nix/Server

- `main_ip`: Main server IP address
- `nvm_ip`: NVM server IP address
- `name_l`: Main server name (lowercase)
- `nvm_name`: NVM server name
- `main_server_keyfile`: Main server SSH keyfile name
- `nvm_server_keyfile`: NVM server SSH keyfile name

1. **Apply your configuration**

   ```bash
   nixup  # Now loads your secrets from 1Password
   ```

## Environment Variables

The system uses these environment variables loaded from 1Password:

- `NIX_PERSONAL_EMAIL`: Your personal email address
- `NIX_GITHUB_USER`: Your GitHub username
- `NIX_SIGNING_KEY`: Your SSH signing key
- `NIX_SSH_MAIN_GITHUB_KEY`: Your main SSH public key
- `NIX_SSH_MAIN_GITHUB_KEYFILE`: Your main GitHub SSH keyfile name
- `NIX_LAPTOP_NAME`: Your laptop hostname
- `NIX_FULL_NAME`: Your full username
- `NIX_SERVER_IP_MAIN`: Main server IP
- `NIX_SERVER_IP_NVM`: NVM server IP
- `NIX_SERVER_NAME_L`: Main server name
- `NIX_SERVER_NVM_NAME`: NVM server name
- `NIX_SSH_MAIN_SERVER_KEYFILE`: Main server SSH keyfile name
- `NIX_SSH_NVM_SERVER_KEYFILE`: NVM server SSH keyfile name
- `NIX_PRIVATE_EMAIL`: Your alternate SSH email address
- `NIX_PRIVATE_USER`: Your alternate username
- `NIX_PRIVATE_USER_SHORT`: Your alternate short username
- `NIX_PRIVATE_SIGNING_KEY`: Your alternate SSH signing key
- `NIX_SSH_PRIVATE_GITHUB_KEY`: Your alternate SSH public key
- `NIX_SSH_PRIVATE_GITHUB_KEYFILE`: Your alternate GitHub SSH keyfile name
- `NIX_PRIVATE_GITDIR`: Git directory for alternate config
- `NIX_SSH_MAIN_SERVER_KEY`: Your main server SSH public key
- `NIX_SSH_NVM_SERVER_KEY`: Your NVM server SSH public key
- `NIX_FORGEJO_DOMAIN`: Your Forgejo instance URL

## Bootstrap Mode Override

You can manually force bootstrap mode:

```bash
NIX_BOOTSTRAP_MODE=1 darwin-rebuild switch --flake ~/dotfiles/nix
```

## Public Repository Safety

This configuration is designed to be safe for public repositories:

- No secrets stored in the repository
- Bootstrap mode provides safe placeholder values
- 1Password integration keeps sensitive data encrypted
- Graceful fallbacks if 1Password is unavailable

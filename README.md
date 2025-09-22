# macOS Dotfiles with Nix-Darwin

> Declarative macOS system configuration using nix-darwin, managing applications, system settings, development tools, and more.

## 🚀 Quick Start

### Method 1: Bootstrap Script (Recommended)

```bash
curl -sSL https://raw.githubusercontent.com/mmenanno/dotfiles/main/bootstrap.sh | bash
```

### Method 2: Manual Installation

```bash
# Install Nix
sh <(curl -L https://nixos.org/nix/install) --daemon

# Clone dotfiles
git clone https://github.com/mmenanno/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Enable flakes
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf

# Build and activate
darwin-rebuild switch --flake ~/dotfiles/nix#macbook_setup
```

## 📦 What Gets Installed

### Applications (85+ apps via Homebrew)

- **Development**: Cursor, VS Code, Docker, Postman, Proxyman
- **Communication**: Discord, Slack, Signal, WhatsApp, Telegram
- **Media**: VLC, HandBrake, Steam, Plex
- **Productivity**: 1Password, Rectangle, Obsidian, Logseq
- **System**: Tailscale, LuLu, Gas Mask, CleanMyMac

### Development Environment

- **Languages**: Python, Ruby, Node.js (via mise)
- **Tools**: Git, GitHub CLI, SSH configuration
- **Shell**: Zsh with Starship prompt, zinit plugins

### System Configuration

- **Dock**: Custom app layout and settings
- **Trackpad**: Natural scrolling, force click settings
- **Finder**: Show extensions, status bar configuration
- **Fonts**: Nerd Fonts + custom fonts (PlayfairDisplay, etc.)

### App Configurations

- **Cursor**: Complete settings and keybindings
- **Rectangle**: Window management shortcuts
- **Tailscale**: Auto-start and VPN settings
- **Git**: Signing, credentials, aliases

## 🔧 Post-Installation

After running the bootstrap:

1. **Restart your terminal** to load new shell configuration
2. **Sign into applications** that require authentication
3. **Configure 1Password** for SSH/Git signing (see `BOOTSTRAP.md` for required items and environment variables)
4. **Run `nixup` or `nx up`** to rebuild configuration

## 🛠 Customization

### Adding Applications

Edit `nix/modules/system/homebrew.nix` to add new casks:

```nix
casks = [
  "your-new-app"
  # ... existing apps
];
```

### Modifying System Settings

Edit `nix/modules/system/system-defaults.nix` for system preferences.

### Updating Development Tools

Edit `nix/modules/home/mise.nix` to manage language versions.

## 📱 Available Commands

- `nixup` or `nx up` - Rebuild and switch configuration
- `nixedit` or `nx edit` - Open dotfiles in Cursor
- `nx check` or `nx c` - Validate flake configuration
- `nx update` or `nx u` - Update flake dependencies
- `nx status` or `nx s` - Show git status
- `nx diff` or `nx d` - Show configuration changes (dry-run)
- `nx clean` or `nx cl` - Clean old generations
- `nx help` - Show all available commands
- `mise list` - Show installed development tools

## 🔄 Updating

```bash
cd ~/dotfiles
git pull
nx up      # or nixup
```

## 📁 Repository Structure

```text
├── nix/
│   ├── flake.nix                      # Main flake configuration
│   ├── home.nix                       # Home Manager imports
│   ├── modules/
│   │   ├── system/                    # nix-darwin (system-wide)
│   │   │   ├── homebrew.nix           # Applications (casks)
│   │   │   ├── system-defaults.nix    # macOS system settings
│   │   │   ├── packages.nix           # System packages
│   │   │   └── ...
│   │   └── home/                      # Home Manager (user)
│   │       ├── cursor.nix             # Cursor settings
│   │       ├── git.nix                # Git configuration
│   │       ├── mise.nix               # Language/runtime manager
│   │       └── ...
│   └── files/                         # Static files (fonts, PWAs, etc.)
├── bin/                               # Utility scripts
│   ├── nx                             # Main nix management script
│   ├── nixup-with-secrets             # Bootstrap-aware rebuild
│   ├── gbclean                        # Git branch cleanup
│   └── ...                            # Other development tools
├── bootstrap.sh                       # Setup script
└── README.md                          # This file
```

## 🆘 Troubleshooting

### Common Issues

#### Build fails with "experimental features not enabled"

```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

#### Permission denied during installation

- Ensure you have admin privileges
- Restart terminal after Nix installation

#### Applications not found

- Run `nx up` to reapply Homebrew casks via nix-homebrew
- Check `nix/modules/system/homebrew.nix` for typos in cask names

### Getting Help

1. Check [nix-darwin documentation](https://daiderd.com/nix-darwin/)
2. Browse [Home Manager options](https://nix-community.github.io/home-manager/options.html)
3. Open an issue in this repository

## 🔒 Security Notes

- All configurations are declarative and version-controlled
- No secrets or credentials are stored in this repository
- 1Password integration provides secure credential management
- SSH keys and signing keys are managed externally

## ⚡ Performance

- **Cold install**: ~15-20 minutes (downloads all applications)
- **Updates**: ~2-5 minutes (only changed components)
- **Rollbacks**: Instant (nix generations)

## 🌟 Features

- ✅ **Declarative**: Everything defined in configuration files
- ✅ **Reproducible**: Same setup on any macOS machine
- ✅ **Rollback**: Previous configurations always available
- ✅ **Modular**: Easy to enable/disable components
- ✅ **Version-controlled**: Track all system changes in git

---

*This configuration is optimized for software development on macOS with a focus on reproducibility and maintainability.*

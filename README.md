# macOS Dotfiles with Nix-Darwin

> Declarative macOS system configuration using nix-darwin, managing applications, system settings, development tools, and more. Supports multiple machines (personal and work) from a single repo.

## 🚀 Quick Start

### Personal Machine

#### Method 1: Bootstrap Script (Recommended)

```bash
curl -sSL https://raw.githubusercontent.com/mmenanno/dotfiles/main/bootstrap.sh | bash
```

#### Method 2: Manual Installation

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

### Work Machine

```bash
# Install Nix
sh <(curl -L https://nixos.org/nix/install) --daemon

# Clone dotfiles
git clone https://github.com/mmenanno/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Enable flakes
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf

# Bootstrap (installs 1Password CLI and essentials)
NIX_BOOTSTRAP_MODE=1 sudo darwin-rebuild switch --flake ~/dotfiles/nix#macbook_setup --impure

# After bootstrap: sign into 1Password, add Work item to Nix vault with hostname field
# Then run nx up — config is auto-detected via hostname
nx up
```

The `nx` script auto-detects which configuration to use by comparing the local hostname against the value stored in 1Password (`Nix/Work/hostname`). No manual config name selection is needed after initial setup.

## 📦 What Gets Installed

### Both Machines (Shared)

- **Development**: VS Code, Docker, Git, GitHub CLI, Node.js
- **Tools**: 1Password, Rectangle, iTerm2, Claude Code
- **Shell**: Zsh with Starship prompt, zinit plugins
- **System**: Nerd Fonts, macOS defaults, Dock configuration

### Personal Machine (Additional)

- **Apps**: Discord, Slack, Signal, Steam, Plex, VLC, Obsidian, and 60+ more
- **Services**: Tailscale, PWA apps (Gmail, Google Calendar)
- **AI Tools**: Codex, Gemini CLI, Claude Skills
- **Dev**: Rust, Go, Python, Hugo, MariaDB, and more

### Work Machine (Focused)

- **Apps**: Chrome, Slack, Notion, Zoom, Sequel Ace
- **Dev**: Ruby/Rails tooling, Docker, ejson
- **Dock**: Chrome, Google Meet, 1Password, iTerm, VS Code, Slack

### System Configuration

- **Dock**: Custom app layout per machine
- **Trackpad**: Natural scrolling, force click settings
- **Finder**: Show extensions, status bar configuration
- **Fonts**: Nerd Fonts + custom fonts (PlayfairDisplay, etc.)

### App Configurations

- **Rectangle**: Window management shortcuts
- **Git**: Signing, credentials, aliases

## 🔧 Post-Installation

After running the bootstrap:

1. **Restart your terminal** to load new shell configuration
2. **Sign into applications** that require authentication
3. **Configure 1Password** for SSH/Git signing (see `BOOTSTRAP.md` for required items and environment variables)
4. **Run `nixup` or `nx up`** to rebuild configuration

## 🛠 Customization

### Adding Applications

Edit `nix/modules/system/homebrew.nix`:

- **Both machines**: Add to `commonCasks`
- **Personal only**: Add to `personalOnlyCasks`

Same pattern applies for `brews` and `masApps`.

### Adding Packages

Edit `nix/modules/system/packages.nix`:

- **Both machines**: Add to `commonPackages`
- **Personal only**: Add to `personalOnlyPackages`

### Modifying System Settings

Edit `nix/modules/system/system-defaults.nix` for system preferences.

### Updating Development Tools

Edit `nix/modules/home/mise.nix` to manage language versions.

### Machine-Specific Module Logic

Modules receive `isWorkMachine ? false`. Use conditionals for machine-specific behavior:

```nix
{ isWorkMachine ? false, ... }:
{
  # Attribute sets: lib.optionalAttrs
  settings = lib.optionalAttrs (!isWorkMachine) { ... };

  # Lists: if/then/else or lib.optionals
  items = commonItems ++ (if isWorkMachine then [] else personalItems);
}
```

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
│   ├── flake.nix                      # Entry point — darwinConfigurations for each machine
│   ├── home.nix                       # Home Manager imports (selects modules by machine)
│   ├── modules/
│   │   ├── default.nix                # Module index (systemModules, homeModules, work variants)
│   │   ├── lib.nix                    # Helpers: getEnvOrFallback, getPersonalEnvOrFallback
│   │   ├── system/                    # nix-darwin (system-wide)
│   │   │   ├── homebrew.nix           # Applications (common + machine-specific)
│   │   │   ├── system-defaults.nix    # macOS system settings + dock
│   │   │   ├── packages.nix           # System packages (common + machine-specific)
│   │   │   └── ...
│   │   └── home/                      # Home Manager (user)
│   │       ├── git.nix                # Git configuration
│   │       ├── ssh.nix                # SSH hosts and keys
│   │       ├── mcp-shared.nix         # Shared MCP/identity config
│   │       ├── claude.nix             # Claude Code settings
│   │       ├── mise.nix               # Language/runtime manager
│   │       └── ...
│   └── files/                         # Static files (fonts, PWAs, etc.)
├── bin/                               # Utility scripts
│   ├── nx                             # Main nix management script
│   ├── nixup-with-secrets             # Bootstrap-aware rebuild with 1Password
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
- Machine detection uses hostname from 1Password (not hardcoded)

## ⚡ Performance

- **Cold install**: ~15-20 minutes (downloads all applications)
- **Updates**: ~2-5 minutes (only changed components)
- **Rollbacks**: Instant (nix generations)

## 🌟 Features

- ✅ **Declarative**: Everything defined in configuration files
- ✅ **Multi-machine**: Single repo supports personal and work machines
- ✅ **Reproducible**: Same setup on any macOS machine
- ✅ **Rollback**: Previous configurations always available
- ✅ **Modular**: Easy to enable/disable components
- ✅ **Version-controlled**: Track all system changes in git

---

*This configuration is optimized for software development on macOS with a focus on reproducibility and maintainability.*

# Dotfiles Repository

Nix-darwin + Home Manager configuration for macOS.

## Commands

```bash
nx check    # Validate flake (ALWAYS run before nx up)
nx diff     # Preview changes before applying
nx up       # Apply configuration (darwin-rebuild switch)
nx lint     # Run statix + deadnix code quality checks
nx build    # Build without applying
nx clean    # Clean old generations
```

## Repository Structure

```text
dotfiles/
├── nix/
│   ├── flake.nix              # Entry point - defines darwinConfigurations
│   ├── home.nix               # Home Manager entry point
│   └── modules/
│       ├── default.nix        # Module index (systemModules + homeModules lists)
│       ├── lib.nix            # dotlib: getEnvOrFallback helper
│       ├── system/            # nix-darwin modules (OS, apps, services)
│       └── home/              # Home Manager modules (user programs, dotfiles)
└── bin/                       # Shell scripts (nx, gbclean, etc.)
```

## Key Modules

- `ai-globals.nix` - Generates global CLAUDE.md, AGENTS.md, GEMINI.md
- `claude.nix` - Claude Code settings and MCP servers
- `claude-skills.nix` - Skill imports from repos (ralph-claude-code)
- `zsh.nix` - Shell config with zinit plugin management
- `modern-cli-tools.nix` - bat, eza, ripgrep, fd, atuin, etc.

## Adding a New Module

1. Create file in `nix/modules/home/` (user) or `nix/modules/system/` (OS)
2. Use signature: `{ config, pkgs, lib, ... }:`
3. Add to list in `nix/modules/default.nix` (`homeModules` or `systemModules`)
4. Run `nx check` then `nx diff` then `nx up`

## Troubleshooting

```bash
nx check                    # Validate before anything else
nix log .#darwinConfigurations.mm.system  # View build logs
nix repl --file nix/flake.nix            # Debug expressions
darwin-rebuild --list-generations         # See history
darwin-rebuild --rollback                 # Undo last change
```

## Gotchas

- **Bootstrap mode**: `NIX_BOOTSTRAP_MODE=1` uses placeholder values; check `dotlib.getEnvOrFallback`
- **System vs Home**: System = nix-darwin (OS-level), Home = Home Manager (user-level)
- **Global configs are Nix-managed**: `~/.claude/CLAUDE.md` is symlink - edit `ai-globals.nix`
- **Module pattern**: Import in `modules/default.nix`, use `{ config, pkgs, ... }:` signature
- **1Password in scripts**: Use `op plugin run -- <cmd>` in subshells (aliases don't inherit)

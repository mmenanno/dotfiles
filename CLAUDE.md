# Dotfiles Repository

Nix-darwin + Home Manager configuration for macOS.

## Commands

```bash
nx check    # Validate flake (ALWAYS run before nx up)
nx diff     # Preview changes before applying
nx up       # Apply full configuration (darwin-rebuild switch)
nx up -hm   # Apply Home Manager only (faster for config changes)
nx lint     # Run statix + deadnix code quality checks
nx build    # Build without applying
nx clean    # Clean old generations
nx managed  # Show mutable config file status (alias: nx m)
```

## Multi-Machine Support

Two `darwinConfigurations`: `macbook_setup` (personal) and `work_macbook` (work).
Auto-detected via hostname matching against 1Password `Nix/Work/hostname`.

- **`isWorkMachine`** boolean passed via `specialArgs`/`extraSpecialArgs`; modules accept with `? false` default
- **Module lists**: `systemModules`/`homeModules` (personal), `workSystemModules`/`workHomeModules` (work) in `default.nix`
- **DRY pattern for lists**: Use `commonItems ++ (if isWorkMachine then [] else personalOnlyItems)` — don't duplicate shared items
- **DRY pattern for env vars**: Use `dotlib.getPersonalEnvOrFallback isWorkMachine` for personal-only secrets (returns `""` on work machine)
- **Conditional attrs**: Use `lib.optionalAttrs (!isWorkMachine) { ... }` for optional attribute sets

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

## Mutable Config Files

`mutable-files.nix` deploys writable copies instead of read-only HM symlinks for files that apps need to modify (VS Code settings, Claude settings). Uses `home.file.*.enable = lib.mkForce false` to suppress symlinks while keeping `.source` evaluable, then an activation script copies with conflict detection. Baselines stored at `~/.local/share/nix-managed-baselines/`.

- `nx m` — status, `nx m d <name>` — diff in VS Code, `nx m r <name>` — revert to Nix version, `nx m a <name>` — apply app changes into Nix module
- Shorthands: `claude`, `vscode`, `vsmcp`, `all`
- Zsh completions in `completions/_nx`

## Key Modules

- `ai-globals.nix` - Generates global CLAUDE.md, AGENTS.md, GEMINI.md
- `claude.nix` - Claude Code settings and MCP servers
- `claude-skills.nix` - Skill imports from repos (ralph-claude-code)
- `zsh.nix` - Shell config with zinit plugin management
- `mutable-files.nix` - Writable copies of app config files with conflict detection
- `modern-cli-tools.nix` - bat, eza, ripgrep, fd, atuin, etc.

## Adding a New Module

1. Create file in `nix/modules/home/` (user) or `nix/modules/system/` (OS)
2. Use signature: `{ config, pkgs, lib, ... }:`
3. Add to list in `nix/modules/default.nix` (`homeModules` or `systemModules`)
4. Run `nx check` then `nx diff` then `nx up`

## Troubleshooting

```bash
nx check                    # Validate before anything else
nix eval nix/#darwinConfigurations.macbook_setup.system --apply 'x: "ok"'  # Fast eval check (much faster than nx check)
nix log .#darwinConfigurations.mm.system  # View build logs
nix repl --file nix/flake.nix            # Debug expressions
darwin-rebuild --list-generations         # See history
darwin-rebuild --rollback                 # Undo last change
```

## Gotchas

- **`nix flake check` is slow**: Use `nix eval nix/#darwinConfigurations.X.system --apply 'x: "ok"'` for quick validation
- **Atuin drives zsh-autosuggestions**: `atuin init zsh` sets `ZSH_AUTOSUGGEST_STRATEGY=(atuin)` (runs after `initContent`). If you want HISTFILE-driven inline suggestions, override via precmd hook — see `_fix_autosuggest_strategy` in `zsh.nix`
- **Homebrew + Home Manager pattern**: Use `mkHomebrewWrapper` from `mcp-shared.nix` to install via Homebrew but keep Home Manager config (see `claude.nix`, `mise.nix`, `codex.nix`, `gemini.nix`)
- **deadnix catches unused module args**: Don't add `lib` to module args unless it's actually used in the body — use `if/then/else` over `lib.optionalAttrs` when simpler
- **Bootstrap mode**: `NIX_BOOTSTRAP_MODE=1` uses placeholder values; check `dotlib.getEnvOrFallback`
- **System vs Home**: System = nix-darwin (OS-level), Home = Home Manager (user-level)
- **Global configs are Nix-managed**: `~/.claude/CLAUDE.md` is symlink - edit `ai-globals.nix`
- **Module pattern**: Import in `modules/default.nix`, use `{ config, pkgs, ... }:` signature
- **1Password in scripts**: Use `op plugin run -- <cmd>` in subshells (aliases don't inherit)
- **New Nix files must be `git add`ed before eval**: Nix flakes only see git-tracked files — `nix eval` will error on untracked `.nix` files
- **delta is the git pager**: `git diff --no-index` pipes through delta; use `git -c core.pager= diff` to bypass
- **deadnix warnings**: Remove unused `let` bindings - deadnix (part of `nx lint`) fails on dead code

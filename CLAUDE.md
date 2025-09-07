# Nix Dotfiles Configuration

## Build & Deploy Commands

- Apply configuration: `nixup` (alias for darwin-rebuild switch)
- Check flake: `nix flake check ./nix`
- Update dependencies: `nix flake update ./nix`
- Edit config: `nixedit` (opens dotfiles in Cursor)

## Project Structure

- `nix/flake.nix`: Main flake configuration
- `nix/home.nix`: Home Manager configuration imports
- `nix/modules/`: Individual configuration modules
- `nix/modules/claude.nix`: Claude Code settings and permissions

## Code Standards

- Use 2-space indentation for nix files
- Group related imports together
- Add comments for complex configurations
- Keep modules focused and single-purpose

## Key Modules

- `starship.nix`: Terminal prompt configuration
- `zsh.nix`: Shell and environment setup (includes Claude env vars)
- `claude.nix`: Claude Code settings and permissions
- `git.nix`: Git configuration
- `homebrew.nix`: macOS app management
- `packages.nix`: System packages
- `system-defaults.nix`: macOS system preferences

## Workflow

- Test changes with `nix flake check ~/dotfiles/nix` before applying
- Use `nixup` to apply system-wide changes
- Configuration is declarative - edit nix files, don't manually configure
- Claude environment variables are managed in `zsh.nix`
- All changes should be committed to git for version control

## Development Tools

- Editor: Cursor (configured as $EDITOR)
- Shell: zsh with zinit plugin manager
- Prompt: Starship (also used in Claude status line)
- Package manager: Nix + Home Manager for user packages, Homebrew for GUI apps

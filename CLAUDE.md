# Nix Dotfiles Configuration

## Build & Deploy Commands

- Apply configuration: `nixup` (alias for darwin-rebuild switch)
- Check flake: `nix flake check ./nix`
- Update dependencies: `nix flake update ./nix`
- Edit config: `nixedit` (opens dotfiles in Cursor)

## Project Structure

- `nix/flake.nix`: Main flake configuration
- `nix/home.nix`: Home Manager configuration imports
- `nix/modules/system/` and `nix/modules/home/`: Individual configuration modules
- `nix/modules/home/claude.nix`: Claude Code settings and permissions

## Code Standards

- Use 2-space indentation for nix files
- Group related imports together
- Add comments for complex configurations
- Keep modules focused and single-purpose

## Key Modules

- `home/starship.nix`: Terminal prompt configuration
- `home/zsh.nix`: Shell and environment setup (includes Claude env vars)
- `home/claude.nix`: Claude Code settings and permissions
- `home/git.nix`: Git configuration
- `system/homebrew.nix`: macOS app management
- `system/packages.nix`: System packages
- `system/system-defaults.nix`: macOS system preferences

## Workflow

- Test changes with `nix flake check ./nix` before applying
- Use `nixup` to apply system-wide changes
- Configuration is declarative - edit nix files, don't manually configure
- Claude environment variables are managed in `zsh.nix`
- All changes should be committed to git for version control

### Pull Request Workflow

When instructed to "make a PR for this repo", follow this complete workflow:

1. **Create a new branch** for the changes
2. **Commit the changes** to the branch
3. **Push the branch** to the remote repository
4. **Create a pull request** using GitHub tools
5. **Monitor CI/CD workflows** until they complete without errors
6. **Merge the pull request** once workflows pass
7. **Run `gbclean`** after merging to clean up local branches

This is the standard expectation when PR creation is requested - the full end-to-end process from branch creation through cleanup.

## Development Tools

- Editor: Cursor (configured as $EDITOR)
- Shell: zsh with zinit plugin manager
- Prompt: Starship (also used in Claude status line)
- Package manager: Nix + Home Manager for user packages, Homebrew for GUI apps

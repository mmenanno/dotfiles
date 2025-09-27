# Dotfiles Repository - Claude Code Configuration

This file defines repository-specific Claude behavioral preferences for working on this Nix dotfiles configuration. It extends the global `~/.claude/CLAUDE.md` with dotfiles-specific requirements and overrides.

## Dotfiles-Specific Behavioral Overrides

### Nix Configuration Focus

- Prioritize declarative configuration over imperative changes
- Understand the modular architecture in `nix/modules/`
- Use `dotlib` helper functions for environment variables
- Reference existing patterns when creating new modules

### Development Workflow for Dotfiles

- Always test with `nx check` before applying changes
- Use `nx diff` to preview changes before `nx up`
- Maintain separation between system and home modules
- Keep secrets in 1Password, never in configuration files

## Dotfiles-Specific Tool Integration

### Nix Ecosystem Deep Integration

- Understand nix-darwin and Home Manager relationship
- Navigate the flake.nix structure and module system
- Use appropriate Nix functions and patterns
- Leverage the custom `dotlib` utility functions

### Development Environment Context

- Understand the multi-tool setup (Cursor, VS Code, terminal tools)
- Work with the custom `nx` wrapper script and its commands
- Integrate with the 1Password CLI workflow for secrets
- Respect the declarative nature of the entire system

## Repository Context Integration

This repository-specific configuration works with the global Claude configuration:

- **Global config** (`~/.claude/CLAUDE.md`) provides universal behavioral preferences
- **This file** adds dotfiles-specific context and requirements
- **AGENTS.md** (both global and local) defines execution constraints
- **Nix modules** handle the actual system configuration management

Focus on this repository's unique aspects: Nix ecosystem, modular architecture, and declarative system management.

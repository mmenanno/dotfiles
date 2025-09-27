---
type: always
description: "Dotfiles Repository AI Integration"
---

# Dotfiles Repository AI Integration

This rule provides repository-specific AI integration for this Nix dotfiles configuration. Global AI configurations are managed separately in the home directory.

## Repository-Specific Context

This is a **Nix-based dotfiles repository** with:

- **Declarative system configuration** using nix-darwin and Home Manager
- **Modular architecture** in `nix/modules/system/` and `nix/modules/home/`
- **Custom utility scripts** in `bin/` directory
- **1Password integration** for secrets management

## Dotfiles-Specific Validation

Beyond global validation requirements, also execute:

```bash
nx diff          # Show pending Nix changes
brew bundle      # Validate Homebrew dependencies if needed
```

## Repository-Specific Behavior

- **Prioritize declarative changes** over imperative system modifications
- **Reference existing module patterns** when creating new configurations
- **Maintain modular architecture** - avoid monolithic configuration files
- **Use dotlib helpers** for environment variable management

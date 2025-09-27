---
type: auto_attached
patterns: ["nix/**/*.nix", "*.nix", "flake.lock"]
description: "Nix development and configuration rules"
---

# Nix Development Guidelines

This rule applies when working with Nix configuration files.

## File Structure

- **nix/flake.nix**: Main configuration entry point
- **nix/modules/system/**: System-level configurations
- **nix/modules/home/**: User-level configurations
- **nix/files/**: Static assets (fonts, PWA apps, etc.)

## Code Style

- Use 2-space indentation
- Create small, focused modules
- Use hyphenated filenames (e.g., `system-defaults.nix`)
- Group related imports together
- Add comments for complex configurations

## Validation Workflow

1. Test changes: `nx check`
2. Build configuration: `nx build`
3. Apply changes: `nx up`
4. Validate with shellcheck and markdownlint

## Best Practices

- Keep modules focused and single-purpose
- Use descriptive variable names
- Leverage the dotlib helper functions
- Maintain secrets in 1Password, not in configuration files

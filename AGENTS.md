# Dotfiles Repository - AI Agent Execution Playbook

This file defines repository-specific executable constraints and validation workflows for AI programming assistants working on this Nix dotfiles configuration. It extends the global AGENTS.md with dotfiles-specific requirements.

## Mandatory Validation Commands

Before any code changes are submitted or merged, AI agents MUST execute these validation commands:

### Build & Check Commands

```bash
# Validate Nix configuration
nx check

# Build configuration (dry-run)
nx build
```

### Linting & Style Checks

```bash
# Shell script validation
shellcheck bin/*

# Markdown linting
markdownlint **/*.md
```

### Testing Commands

```bash
# No specific test commands for this infrastructure repo
# Individual projects should define their own test suites
```

## Code Style Guidelines

### Nix Configuration

- Use 2-space indentation
- Create small, focused modules
- Use hyphenated filenames (e.g., `system-defaults.nix`)
- Group related imports together
- Add comments for complex configurations

### Shell Scripts

- Use `#!/bin/bash` shebang
- Include `set -euo pipefail` for safety
- Must pass `shellcheck` validation
- Use lowercase, short names (e.g., `nx`, `gbclean`)

### Markdown Documentation

- Keep sections concise and scannable
- Must pass `markdownlint` validation
- Use consistent heading hierarchy

## PR Validation Requirements

All AI-generated pull requests MUST:

1. **Pass all validation commands** listed above
2. **Use conventional commits**: `feat:`, `fix:`, `refactor:`, etc.
3. **Include clear descriptions** with rationale and before/after notes
4. **Update documentation** when adding new modules or functionality
5. **Pass CI workflows** in `.github/workflows/lint.yml`

## Prohibited Operations

AI agents are PROHIBITED from executing these dangerous operations:

- `rm -rf` or other destructive file operations
- `sudo` commands that modify system state
- Database migrations or data modifications
- External API calls with `curl`/`wget` to unknown endpoints
- Deployment commands
- Operations that modify production environments

## Allowed Operations

AI agents MAY execute these safe, idempotent operations:

- Configuration validation (`nx check`)
- Linting and style checks
- Build operations that don't modify system state
- File reading operations
- Git status and diff operations
- Documentation generation

## Security Requirements

- No secrets in repository files
- Use 1Password CLI for secret management
- All configuration changes require code review
- Maintain principle of least privilege for AI operations

## Build System Commands

### Primary Commands

- `nx up` or `nixup`: Apply configuration changes
- `nx check` or `nx c`: Validate configuration
- `nx build` or `nx b`: Build without applying
- `nx diff` or `nx d`: Show pending changes

### Development Commands

- `nx edit` or `nixedit`: Open configuration in editor
- `nx status` or `nx s`: Show git status
- `nx clean` or `nx cl`: Clean old generations
- `nx help` or `nx h`: Show available commands

## Project Structure

- `nix/flake.nix`: Main configuration entry point
- `nix/modules/system/`: System-level configurations
- `nix/modules/home/`: User-level configurations
- `bin/`: Utility scripts and tools
- `.github/workflows/`: CI/CD automation

# Repository Guidelines

## Project Structure & Module Organization

- `nix/flake.nix`: Main flake; entry point for builds.
- `nix/home.nix`: Home Manager imports.
- `nix/modules/system/*.nix` and `nix/modules/home/*.nix`: Modular configs (e.g., `system/homebrew.nix`, `system/system-defaults.nix`, `home/git.nix`, `home/cursor.nix`).
- `nix/files/`: Static assets (fonts, PWA apps, etc.).
- `bin/`: Utility scripts (e.g., `nx`, `nixup-with-secrets`, `gbclean`, `gfsync`, `gclone`, `webm2mp4`, Rails MCP tools).
- `bootstrap.sh` + `BOOTSTRAP.md`: First‑time setup and 1Password bootstrap.
- `.github/workflows/`: Lint and automation.

## Build, Test, and Development Commands

- `nixup` or `nx up`: Rebuild and switch configuration (alias for `darwin-rebuild switch`).
- `nx check` or `nx c`: Validate flake and module integrity.
- `nx update` or `nx u`: Update inputs; commit lockfile changes.
- `nx build` or `nx b`: Build configuration without applying.
- `nx diff` or `nx d`: Show what would change (dry-run).
- `nx clean` or `nx cl`: Clean old generations with progress indicator.
- `nixedit` or `nx edit`: Open this repo in the configured editor.
- `nx status` or `nx s`: Show git status of dotfiles.
- `nx help` or `nx h`: Show available commands.
- Troubleshooting: `brew bundle` from repo root if Homebrew casks drift.

## Coding Style & Naming Conventions

- Nix: 2‑space indentation, small focused modules, hyphenated filenames (e.g., `system-defaults.nix`).
- Shell: `#!/bin/bash`, `set -euo pipefail`, pass `shellcheck` (CI enforces).
- Markdown: Keep sections concise; passes `markdownlint` (line length relaxed in CI).
- Format: Use `nixfmt` if available (`nixfmt --check` runs in CI when present).
- Scripts: Lowercase, short names (e.g., `nx`, `gbclean`, `gfsync`, `webm2mp4`); keep shared helpers in `bin/shared`.

## Testing Guidelines

- Prefer functional checks over unit tests for configs:

  - Run `nx check` locally before PRs.
  - Lint shell/markdown changes: `shellcheck bin/*` and `markdownlint **/*.md`.
- CI: `.github/workflows/lint.yml` validates Nix syntax, shell scripts, markdown, and workflow YAML.

## Commit & Pull Request Guidelines

- Conventional Commits: `feat: …`, `fix: …`, `refactor: …` (see `git log`).
- PRs must:

  - Describe the change and rationale; link related issues.
  - Include before/after notes for user‑visible behavior (screenshots only if relevant).
  - Update docs (`README.md`, `BOOTSTRAP.md`, or module comments) when adding modules/apps.
  - Pass CI and avoid hardcoded secrets or personal paths.

## Security & Configuration Tips

- No secrets in repo; use 1Password CLI. See `BOOTSTRAP.md` for required items and envs.
- New machine? `op signin`, then `nixup`. To force placeholders: `NIX_BOOTSTRAP_MODE=1 darwin-rebuild switch --flake nix#macbook_setup`.
- **For Claude/agent behavior specifics, always refer to `CLAUDE.md` as the authoritative source of truth.**

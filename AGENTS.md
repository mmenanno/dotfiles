# Repository Guidelines

## Project Structure & Module Organization

- `nix/flake.nix`: Main flake; entry point for builds.
- `nix/home.nix`: Home Manager imports.
- `nix/modules/*.nix`: Modular configs (e.g., `homebrew.nix`, `system-defaults.nix`, `git.nix`, `cursor.nix`).
- `nix/files/`: Static assets (fonts, PWA apps, etc.).
- `bin/`: Utility scripts (e.g., `nixup-with-secrets`, `gbclean`).
- `bootstrap.sh` + `BOOTSTRAP.md`: First‑time setup and 1Password bootstrap.
- `.github/workflows/`: Lint and automation.

## Build, Test, and Development Commands

- `nixup`: Rebuild and switch configuration (alias for `darwin-rebuild switch`).
- `darwin-rebuild switch --flake nix#macbook_setup`: Apply system config explicitly.
- `nix flake check nix`: Validate flake and module integrity.
- `nix flake update nix`: Update inputs; commit lockfile changes.
- `nixedit`: Open this repo in the configured editor.
- Troubleshooting: `brew bundle` from repo root if Homebrew casks drift.

## Coding Style & Naming Conventions

- Nix: 2‑space indentation, small focused modules, hyphenated filenames (e.g., `system-defaults.nix`).
- Shell: `#!/bin/bash`, `set -euo pipefail`, pass `shellcheck` (CI enforces).
- Markdown: Keep sections concise; passes `markdownlint` (line length relaxed in CI).
- Format: Use `nixfmt` if available (`nixfmt --check` runs in CI when present).
- Scripts: Lowercase, short names (e.g., `gbclean`, `webm2mp4`); keep shared helpers in `bin/shared`.

## Testing Guidelines

- Prefer functional checks over unit tests for configs:
  
  - Run `nix flake check nix` locally before PRs.
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
- New machine? `op signin`, then `nixup`. To force placeholders: `NIX_BOOTSTRAP_MODE=1 darwin-rebuild switch --flake nix`.
- For Claude/agent behavior specifics, see `CLAUDE.md`.

{ lib, pkgs, secretFile, ... }:

let
  # Dedicated gh CLI token (op://Nix/Github/dev_token) — scoped for general gh use,
  # including read:org. Kept separate from github_mcp_token so each token can carry
  # only the scopes its consumer needs. Written (0600) by `nx up`; see mcp-shared.nix
  tokenFile = secretFile "github-dev-token";
in
{
  programs.gh = {
    enable = true;
    settings = {
      editor = "code";
      git_protocol = "ssh";
      prompt = "enabled";
    };
    extensions = [ pkgs.gh-stack ];
  };

  # Persist gh CLI auth from the 1Password-sourced token.
  # Why: the `alias gh="op plugin run -- gh"` approach only applies to interactive zsh —
  # Dock-launched GUI apps (Claude Code UI, VS Code) and non-interactive subshells
  # spawn `gh` without that alias and without the shell env, so authentication fails.
  # Logging gh in with its own stored credential makes `gh` work everywhere.
  #
  # gh keeps the token in the macOS Keychain (hosts.yml only records the user), so
  # compare against `gh auth token`, which reads the Keychain without a network call.
  #
  # `gh auth login` writes to both hosts.yml AND config.yml, but config.yml is a
  # read-only Nix-store symlink (managed by programs.gh.settings). We isolate gh
  # in a temporary GH_CONFIG_DIR so its writes to config.yml are harmless, then
  # copy only the resulting hosts.yml to the real location. That runs in a
  # subshell so its EXIT trap doesn't replace home-manager's own.
  home.activation.ghAuth = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    token_file=${lib.escapeShellArg tokenFile}
    if [ -r "$token_file" ]; then
      # Clear any ambient GitHub tokens: `gh auth token` would report them instead
      # of the stored credential, and `gh auth login` would defer to them rather
      # than persisting (env vars don't survive into Dock-launched app subprocesses).
      gh_clean_env="env -u GITHUB_TOKEN -u GH_TOKEN -u GH_ENTERPRISE_TOKEN -u GITHUB_ENTERPRISE_TOKEN"
      current=$($gh_clean_env ${pkgs.gh}/bin/gh auth token --hostname github.com 2>/dev/null || true)
      if [ "$current" != "$(cat "$token_file")" ]; then
        hosts_file="$HOME/.config/gh/hosts.yml"
        echo -e "\033[0;34mℹ\033[0m Persisting gh CLI authentication"
        mkdir -p "$HOME/.config/gh"
        if ! (
          tmp_dir=$(mktemp -d)
          trap 'rm -rf "$tmp_dir"' EXIT
          $gh_clean_env GH_CONFIG_DIR="$tmp_dir" \
            ${pkgs.gh}/bin/gh auth login \
              --hostname github.com \
              --git-protocol ssh \
              --with-token < "$token_file" \
            && install -m 600 "$tmp_dir/hosts.yml" "$hosts_file"
        ); then
          echo -e "\033[1;33m!\033[0m gh auth login failed; gh keeps its previous credentials"
        fi
      fi
    fi
  '';
}

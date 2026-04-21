{ lib, pkgs, dotlib, ... }:

let
  inherit (dotlib) getEnvOrFallback;
  # Dedicated gh CLI token (op://Nix/Github/dev_token) — scoped for general gh use,
  # including read:org. Kept separate from github_mcp_token so each token can carry
  # only the scopes its consumer needs.
  githubDevToken = getEnvOrFallback "NIX_GITHUB_DEV_TOKEN" "bootstrap-github-token" "placeholder-github-token";
  isPlaceholderToken = builtins.elem githubDevToken [
    "bootstrap-github-token"
    "placeholder-github-token"
  ];
in
{
  programs.gh = {
    enable = true;
    settings = {
      editor = "code";
      git_protocol = "ssh";
      prompt = "enabled";
    };
  };

  # Persist gh CLI auth from the 1Password-sourced token into ~/.config/gh/hosts.yml.
  # Why: the `alias gh="op plugin run -- gh"` approach only applies to interactive zsh —
  # Dock-launched GUI apps (Claude Code UI, VS Code) and non-interactive subshells
  # spawn `gh` without that alias and without the shell env, so authentication fails.
  # Persisting the token in gh's own config file makes `gh` work everywhere.
  home.activation.ghAuth = lib.mkIf (!isPlaceholderToken) (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      hosts_file="$HOME/.config/gh/hosts.yml"
      current=""
      if [ -f "$hosts_file" ]; then
        current=$(sed -n 's/^[[:space:]]*oauth_token:[[:space:]]*//p' "$hosts_file" | head -1)
      fi
      if [ "$current" != "${githubDevToken}" ]; then
        echo -e "\033[0;34mℹ\033[0m Persisting gh CLI authentication to $hosts_file"
        mkdir -p "$HOME/.config/gh"
        # Clear any ambient GitHub tokens so gh persists the token to disk rather than
        # deferring to an env var (which wouldn't survive in Dock-launched app subprocesses).
        env -u GITHUB_TOKEN -u GH_TOKEN -u GH_ENTERPRISE_TOKEN -u GITHUB_ENTERPRISE_TOKEN \
          ${pkgs.gh}/bin/gh auth login \
            --hostname github.com \
            --git-protocol ssh \
            --with-token <<< "${githubDevToken}"
      fi
    ''
  );
}

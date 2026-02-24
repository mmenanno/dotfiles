{ lib, pkgs, ... }:

let
  extensions = [
    "alefragnani.project-manager"
    "alexcvzz.vscode-sqlite"
    "aliariff.auto-add-brackets"
    "aliariff.vscode-erb-beautify"
    "andrewmcgoveran.react-component-generator"
    "anthropic.claude-code"
    "bbenoist.nix"
    "bradlc.vscode-tailwindcss"
    "davidanson.vscode-markdownlint"
    "dbaeumer.vscode-eslint"
    "donjayamanne.githistory"
    "eamodio.gitlens"
    "editorconfig.editorconfig"
    "esbenp.prettier-vscode"
    "github.vscode-github-actions"
    "github.vscode-pull-request-github"
    "golang.go"
    "google.gemini-cli-vscode-ide-companion"
    "graphite.gti-vscode"
    "graphql.vscode-graphql"
    "graphql.vscode-graphql-syntax"
    "gruntfuggly.todo-tree"
    "gusto.packwerk-vscode"
    "hverlin.mise-vscode"
    "itarato.byesig"
    "janisdd.vscode-edit-csv"
    "kenhowardpdx.vscode-gist"
    "koichisasada.vscode-rdbg"
    "mechatroner.rainbow-csv"
    "mrmlnc.vscode-scss"
    "ms-azuretools.vscode-containers"
    "ms-azuretools.vscode-docker"
    "ms-python.debugpy"
    "ms-python.isort"
    "ms-python.python"
    "ms-python.vscode-pylance"
    "ms-vscode-remote.remote-containers"
    "ms-vscode-remote.remote-ssh"
    "ms-vscode-remote.remote-ssh-edit"
    "ms-vscode.atom-keybindings"
    "ms-vscode.remote-explorer"
    "orta.vscode-jest"
    "redhat.vscode-xml"
    "redhat.vscode-yaml"
    "rioj7.regex-text-gen"
    "shopify.polaris-for-vscode"
    "shopify.ruby-extensions-pack"
    "shopify.ruby-lsp"
    "sorbet.sorbet-vscode-extension"
    "stylelint.vscode-stylelint"
    "tamasfe.even-better-toml"
    "tomoki1207.pdf"
    "wayou.vscode-todo-highlight"
    "yzhang.markdown-all-in-one"
  ];
in
{
  home.activation.installEditorsExtensions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    set -euo pipefail

    STATE_DIR="''${XDG_STATE_HOME:-$HOME/.local/state}/ide-extensions"
    mkdir -p "$STATE_DIR"

    # Hash the desired extension list to detect config changes
    DESIRED_HASH="$(printf '%s' '${lib.concatStringsSep "\n" extensions}' | ${pkgs.coreutils}/bin/sha256sum | cut -d' ' -f1)"
    HASH_FILE="$STATE_DIR/extensions.hash"

    if [ -f "$HASH_FILE" ] && [ "$(cat "$HASH_FILE")" = "$DESIRED_HASH" ]; then
      exit 0
    fi

    install_exts() {
      local cli="$1"; shift
      local desired_exts="$1"; shift || true
      if [ ! -x "$cli" ]; then
        return 0
      fi

      # Compute set differences efficiently using sorted temp files
      local tmp_installed tmp_desired
      tmp_installed="$(mktemp)"
      tmp_desired="$(mktemp)"
      # Get installed extensions (unsorted, one per line) directly into temp file
      $cli --list-extensions 2>/dev/null | tr -d '\r' | sed '/^$/d' | sort -u >"$tmp_installed" || true
      printf '%s\n' "$desired_exts" | sed '/^$/d' | sort -u >"$tmp_desired"

      # installed \ desired → uninstall
      local to_uninstall
      to_uninstall="$(comm -23 "$tmp_installed" "$tmp_desired" || true)"
      if [ -n "$to_uninstall" ]; then
        while IFS= read -r ext; do
          [ -z "''${ext:-}" ] && continue
          "$cli" --uninstall-extension "$ext" >/dev/null 2>&1 || true
        done <<<"$to_uninstall"
      fi

      # desired \ installed → install
      local to_install
      to_install="$(comm -13 "$tmp_installed" "$tmp_desired" || true)"
      if [ -n "$to_install" ]; then
        while IFS= read -r ext; do
          [ -z "''${ext:-}" ] && continue
          "$cli" --install-extension "$ext" >/dev/null 2>&1 || true
        done <<<"$to_install"
      fi

      rm -f "$tmp_installed" "$tmp_desired"
    }

    vscode_exts='${lib.concatStringsSep "\n" extensions}'

    vscode_cli=""
    if command -v code >/dev/null 2>&1; then
      vscode_cli="$(command -v code)"
    elif [ -x "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" ]; then
      vscode_cli="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
    fi

    if [ -n "$vscode_cli" ]; then
      install_exts "$vscode_cli" "$vscode_exts"
    fi

    # Cache the hash so subsequent runs skip if nothing changed
    printf '%s' "$DESIRED_HASH" > "$HASH_FILE"
  '';
}

{ config, lib, pkgs, ... }:

let
  commonExtensions = [
    "alefragnani.project-manager"
    "alexcvzz.vscode-sqlite"
    "aliariff.auto-add-brackets"
    "aliariff.vscode-erb-beautify"
    "andrewmcgoveran.react-component-generator"
    "bradlc.vscode-tailwindcss"
    "davidanson.vscode-markdownlint"
    "dbaeumer.vscode-eslint"
    "donjayamanne.githistory"
    "eamodio.gitlens"
    "esbenp.prettier-vscode"
    "github.vscode-github-actions"
    "github.vscode-pull-request-github"
    "golang.go"
    "google.gemini-cli-vscode-ide-companion"
    "graphql.vscode-graphql"
    "graphql.vscode-graphql-syntax"
    "gruntfuggly.todo-tree"
    "gusto.packwerk-vscode"
    "itarato.byesig"
    "janisdd.vscode-edit-csv"
    "kenhowardpdx.vscode-gist"
    "koichisasada.vscode-rdbg"
    "mechatroner.rainbow-csv"
    "mrmlnc.vscode-scss"
    "ms-azuretools.vscode-containers"
    "ms-python.debugpy"
    "ms-python.isort"
    "ms-python.python"
    "ms-python.vscode-pylance"
    "ms-vscode-remote.remote-containers"
    "ms-vscode-remote.remote-ssh"
    "ms-vscode-remote.remote-ssh-edit"
    "ms-vscode.atom-keybindings"
    "ms-vscode.remote-explorer"
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

  vscodeOnlyExtensions = [
    "graphite.gti-vscode"
    "hverlin.mise-vscode"
  ];

  cursorOnlyExtensions = [
    "anthropic.claude-code"
    "anysphere.cursorpyright"
    "anysphere.pyright"
    "bbenoist.nix"
    "editorconfig.editorconfig"
    "ms-azuretools.vscode-docker"
    "orta.vscode-jest"
  ];

  vscodeExtensions = builtins.concatLists [ commonExtensions vscodeOnlyExtensions ];
  cursorExtensions = builtins.concatLists [ commonExtensions cursorOnlyExtensions ];
in
{
  home.activation.installEditorsExtensions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    set -euo pipefail

    uninstall_if_present() {
      local cli="$1"; shift
      local ext
      for ext in "$@"; do
        "$cli" --uninstall-extension "$ext" >/dev/null 2>&1 || true
      done
    }

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

      # Always proceed to reconcile and update to ensure latest versions

      # installed \ desired → uninstall
      local to_uninstall
      to_uninstall="$(comm -23 "$tmp_installed" "$tmp_desired" || true)"
      if [ -n "$to_uninstall" ]; then
        while IFS= read -r ext; do
          [ -z "${ext:-}" ] && continue
          "$cli" --uninstall-extension "$ext" >/dev/null 2>&1 || true
        done <<<"$to_uninstall"
      fi

      # desired \ installed → install
      local to_install
      to_install="$(comm -13 "$tmp_installed" "$tmp_desired" || true)"
      if [ -n "$to_install" ]; then
        while IFS= read -r ext; do
          [ -z "${ext:-}" ] && continue
          "$cli" --install-extension "$ext" >/dev/null 2>&1 || true
        done <<<"$to_install"
      fi

      # Update installed extensions to latest
      "$cli" --update-extensions >/dev/null 2>&1 || true

      rm -f "$tmp_installed" "$tmp_desired"
    }

    vscode_exts='${lib.concatStringsSep "\n" vscodeExtensions}'
    cursor_exts='${lib.concatStringsSep "\n" cursorExtensions}'

    vscode_cli=""
    if command -v code >/dev/null 2>&1; then
      vscode_cli="$(command -v code)"
    elif [ -x "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" ]; then
      vscode_cli="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
    fi

    cursor_cli=""
    if command -v cursor >/dev/null 2>&1; then
      cursor_cli="$(command -v cursor)"
    elif [ -x "/Applications/Cursor.app/Contents/Resources/app/bin/cursor" ]; then
      cursor_cli="/Applications/Cursor.app/Contents/Resources/app/bin/cursor"
    elif [ -x "/Applications/Cursor.app/Contents/Resources/app/bin/code" ]; then
      cursor_cli="/Applications/Cursor.app/Contents/Resources/app/bin/code"
    fi

    if [ -n "$vscode_cli" ]; then
      # Ensure Copilot is not installed in VS Code
      uninstall_if_present "$vscode_cli" \
        github.copilot github.copilot-chat GitHub.copilot GitHub.copilot-chat
      install_exts "$vscode_cli" "$vscode_exts"
    fi

    if [ -n "$cursor_cli" ]; then
      install_exts "$cursor_cli" "$cursor_exts"
    fi
  '';
}



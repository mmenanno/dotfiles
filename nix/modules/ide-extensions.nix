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
    "wakatime.vscode-wakatime"
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

    install_exts() {
      local cli="$1"; shift
      local desired_exts="$1"; shift || true
      if [ ! -x "$cli" ]; then
        return 0
      fi
      local installed
      installed="$($cli --list-extensions 2>/dev/null | tr -d '\r' | sort -u || true)"
      # Uninstall extensions that are no longer desired
      while IFS= read -r ext; do
        [ -z "${ext:-}" ] && continue
        if ! grep -qx "$ext" <<<"$desired_exts"; then
          "$cli" --uninstall-extension "$ext" >/dev/null 2>&1 || true
        fi
      done <<<"$installed"
      while IFS= read -r ext; do
        [ -z "${ext:-}" ] && continue
        if grep -qx "$ext" <<<"$installed"; then
          # Extension already present: reinstall to ensure latest version
          "$cli" --install-extension "$ext" --force >/dev/null 2>&1 || true
        else
          # Not present: install
          "$cli" --install-extension "$ext" >/dev/null 2>&1 || true
        fi
      done <<<"$desired_exts"
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
      "$vscode_cli" --uninstall-extension github.copilot >/dev/null 2>&1 || true
      "$vscode_cli" --uninstall-extension github.copilot-chat >/dev/null 2>&1 || true
      "$vscode_cli" --uninstall-extension GitHub.copilot >/dev/null 2>&1 || true
      "$vscode_cli" --uninstall-extension GitHub.copilot-chat >/dev/null 2>&1 || true
      install_exts "$vscode_cli" "$vscode_exts"
    fi

    if [ -n "$cursor_cli" ]; then
      install_exts "$cursor_cli" "$cursor_exts"
    fi
  '';
}



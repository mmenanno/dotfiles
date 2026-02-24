{ pkgs, homeDirectory, vscodeMcpServers, ... }:
# Scope: Home (Home Manager). Configures VS Code user settings and keybindings.

let
  # Pretty-printed VS Code MCP JSON generated at build time
  vscodeMcpJson = pkgs.runCommand "vscode-mcp.json" { nativeBuildInputs = [ pkgs.jq ]; } ''
    cat > mcp.min.json <<'JSON'
    ${builtins.toJSON {
      mcpServers = vscodeMcpServers;
    }}
    JSON
    jq -S . mcp.min.json > $out
  '';
in
{
  home.file = {
    "Library/Application Support/Code/User/settings.json".text = ''
      {
        "workbench.startupEditor": "none",
        "editor.inlineSuggest.enabled": true,
        "git.autofetch": true,
        "[ruby]": {
          "editor.defaultFormatter": "Shopify.ruby-lsp",
          "editor.formatOnSave": true,
          "editor.tabSize": 2,
          "editor.insertSpaces": true,
          "editor.formatOnType": true,
          "editor.semanticHighLighting.enabled": true,
          "editor.semanticHighlighting.enabled": true,
          "files.trimTrailingWhitespace": true,
          "files.insertFinalNewline": true,
          "files.trimFinalNewlines": true,
          "editor.rulers": [120]
        },
        "byesig.fold": false,
        "byesig.enabled": true,
        "byesig.opacity": 0.5,
        "byesig.showIcon": false,
        "files.trimTrailingWhitespace": true,
        "files.insertFinalNewline": true,
        "editor.multiCursorModifier": "ctrlCmd",
        "editor.formatOnPaste": true,
        "editor.rulers": [120],
        "terminal.integrated.fontFamily": "MesloLGS Nerd Font",
        "git.enabledSmartCommit": true,
        "editor.stickyScroll.enabled": true,
        "[python]": { "editor.formatOnType": true },
        "redhat.telemetry.enabled": true,
        "workbench.colorTheme": "Spinel",
        "ruby.rubocop.useBundler": true,
        "security.workspace.trust.untrustedFiles": "open",
        "markdownlint.config": {
          "no-inline-html": false,
          "single-h1": false
        },
        "git.enableSmartCommit": true,
        "projectManager.git.baseFolders": ["${homeDirectory}/dev"],
        "projectManager.groupList": true,
        "githubPullRequests.pullBranch": "never",
        "window.zoomLevel": -1,
        "[json]": {
          "editor.defaultFormatter": "esbenp.prettier-vscode"
        },
        "remote.SSH.connectTimeout": 150,
        "files.associations": {
          "*.sample": "properties"
        },
        "shopifyGlobal.mysqlEditor": "external",
        "workbench.editor.wrapTabs": true,
        "scm.showHistoryGraph": false,
        "github.copilot.enable": {
          "*": true,
          "yaml": true,
          "plaintext": false,
          "markdown": false
        },
        "github.copilot.editor.enableAutoCompletions": true,
        "editor.wordWrap": "on",
        "workbench.activityBar.orientation": "vertical",
        "editor.fontFamily": "Menlo, Monaco, 'Courier New', monospace, MesloLGS Nerd Font ",
        "rubyLsp.rubyVersionManager": { "identifier": "mise", "path": "${homeDirectory}/.local/bin/mise" },
        "diffEditor.ignoreTrimWhitespace": false,
        "rubyLsp.enabledFeatures": {
          "codeActions": true,
          "diagnostics": true,
          "documentHighlights": true,
          "documentLink": true,
          "documentSymbols": true,
          "foldingRanges": true,
          "formatting": true,
          "hover": true,
          "inlayHint": true,
          "onTypeFormatting": true,
          "selectionRanges": true,
          "semanticHighlighting": true,
          "completion": true,
          "codeLens": true,
          "definition": true,
          "workspaceSymbol": true,
          "signatureHelp": true,
          "typeHierarchy": true
        },
        "rubyLsp.featureFlags": { "tapiocaAddon": true },
        "rubyLsp.addonSettings": {},
        "diffEditor.maxComputationTime": 0,
        "keyboard.dispatch": "keyCode",
        "settingsSync.keybindingsPerPlatform": false,
        "[dockercompose]": {
          "editor.insertSpaces": true,
          "editor.tabSize": 2,
          "editor.autoIndent": "advanced",
          "editor.quickSuggestions": {
            "other": true,
            "comments": false,
            "strings": true
          },
          "editor.defaultFormatter": "redhat.vscode-yaml"
        },
        "[github-actions-workflow]": {
          "editor.defaultFormatter": "redhat.vscode-yaml"
        },
        "claudeCode.preferredLocation": "panel"
      }
    '';

    "Library/Application Support/Code/User/keybindings.json".text = ''
      []
    '';

    # MCP configuration for VS Code (pretty-formatted)
    ".vscode/mcp.json".source = vscodeMcpJson;
  };
}

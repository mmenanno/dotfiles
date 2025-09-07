{ config, lib, pkgs, ... }:

let
  # Import shared utilities
  utilsLib = import ./lib.nix;
  inherit (utilsLib) getEnvOrFallback;

  # Environment-based full name
  fullName = getEnvOrFallback "NIX_FULL_NAME" "bootstrap-user" "placeholder-user";

  # GitHub MCP token with fallback pattern
  githubMcpToken = getEnvOrFallback "NIX_GITHUB_MCP_TOKEN" "bootstrap-github-token" "placeholder-github-token";

  # Pretty-printed Cursor MCP JSON generated at build time
  cursorMcpJson = pkgs.runCommand "cursor-mcp.json" { nativeBuildInputs = [ pkgs.jq ]; } ''
    cat > mcp.min.json <<'JSON'
    ${builtins.toJSON {
      mcpServers = {
        github = {
          type = "stdio";
          command = "github-mcp-server";
          args = [ "stdio" ];
          env = { "GITHUB_PERSONAL_ACCESS_TOKEN" = githubMcpToken; };
        };
        rails = {
          type = "stdio";
          command = "rails-mcp-server";
          args = [ "stdio" ];
          env = {};
        };
      };
    }}
    JSON
    jq -S . mcp.min.json > $out
  '';
in
{
  # Cursor configuration files
  home.file = {
    "Library/Application Support/Cursor/User/settings.json".text = ''
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
        "github.copilot.enable": {
          "*": true,
          "yaml": true,
          "plaintext": false,
          "markdown": false
        },
        "[python]": {
          "editor.formatOnType": true
        },
        "redhat.telemetry.enabled": true,
        "workbench.colorTheme": "Spinel",
        "ruby.rubocop.useBundler": true,
        "security.workspace.trust.untrustedFiles": "open",
        "markdownlint.config": {
          "no-inline-html": false,
          "single-h1": false
        },
        "git.enableSmartCommit": true,
        "projectManager.git.baseFolders": ["/Users/${fullName}/dev"],
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
        "github.copilot.editor.enableAutoCompletions": true,
        "workbench.editor.wrapTabs": true,
        "scm.showHistoryGraph": false,
        "cursor.cpp.disabledLanguages": ["plaintext", "markdown"],
        "editor.wordWrap": "on",
        "workbench.activityBar.orientation": "vertical",
        "editor.fontFamily": "Menlo, Monaco, 'Courier New', monospace, MesloLGS Nerd Font ",
        "rubyLsp.rubyVersionManager": {
          "identifier": "mise"
        },
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
        "rubyLsp.featureFlags": {
          "tapiocaAddon": true
        },
        "rubyLsp.addonSettings": {},
        "diffEditor.maxComputationTime": 0
      }
    '';

    # GitHub MCP configuration for Cursor (pretty-formatted)
    ".cursor/mcp.json".source = cursorMcpJson;

    "Library/Application Support/Cursor/User/keybindings.json".text = ''
      [
        {
          "key": "cmd+i",
          "command": "composerMode.agent"
        },
        {
          "key": "cmd+e",
          "command": "composerMode.background"
        }
      ]
    '';
  };
}

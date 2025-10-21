{ config, pkgs, dotlib, ... }:

# Shared MCP (Model Context Protocol) server configurations and helpers
# This module provides common MCP server definitions and utility functions
# that can be reused across different AI coding assistants (Claude, Cursor, Codex, etc.)

let
  inherit (dotlib) getEnvOrFallback;

  # Helper to create a wrapper package for Homebrew-installed binaries
  # This allows Nix to manage configuration while Homebrew manages updates
  # Gracefully handles missing Homebrew binaries (e.g., in CI environments)
  mkHomebrewWrapper = { name, homebrewBinary, nixBinary ? homebrewBinary }:
    pkgs.writeShellScriptBin nixBinary ''
      # Check if Homebrew binary exists before executing
      if [ -x "/opt/homebrew/bin/${homebrewBinary}" ]; then
        exec /opt/homebrew/bin/${homebrewBinary} "$@"
      else
        echo "Warning: ${name} is not available (Homebrew binary not found at /opt/homebrew/bin/${homebrewBinary})" >&2
        exit 0
      fi
    '';

  # Shared environment variables
  githubMcpToken = getEnvOrFallback "NIX_GITHUB_MCP_TOKEN" "bootstrap-github-token" "placeholder-github-token";

  # Common MCP server configurations
  mcpServers = {
    github = {
      command = "github-mcp-server";
      args = [ "stdio" ];
      env = { GITHUB_PERSONAL_ACCESS_TOKEN = githubMcpToken; };
    };
    rails = {
      command = "rails-mcp-server";
      args = [ "stdio" ];
      env = { };
    };
  };

  # Cursor-specific MCP configuration (includes type field)
  cursorMcpServers = {
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
in
{
  # Export the shared configurations and helpers for use by other modules
  # This allows other modules to import and use these standardized configs
  _module.args = {
    mcpServers = mcpServers;
    cursorMcpServers = cursorMcpServers;
    githubMcpToken = githubMcpToken;
    mkHomebrewWrapper = mkHomebrewWrapper;
  };
}

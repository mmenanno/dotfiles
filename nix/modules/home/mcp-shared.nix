{ pkgs, dotlib, ... }:

# Shared MCP (Model Context Protocol) server configurations and helpers
# This module provides common MCP server definitions and utility functions
# that can be reused across different AI coding assistants (Claude, Codex, etc.)

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
  #
  # GitHub MCP token (classic PAT) scopes:
  #   repo, workflow, write:packages, read:packages, write:repo_hook,
  #   read:repo_hook, gist, notifications, read:user, write:discussion,
  #   read:discussion, project, read:project
  #   Manage at: GitHub Settings > Developer settings > Personal access tokens > Tokens (classic)
  githubMcpToken = getEnvOrFallback "NIX_GITHUB_MCP_TOKEN" "bootstrap-github-token" "placeholder-github-token";

  # Shared identity values (centralized to avoid drift between git.nix and ssh.nix)
  sharedIdentity = {
    personalEmail = getEnvOrFallback "NIX_PERSONAL_EMAIL" "bootstrap@example.com" "placeholder@example.com";
    privateEmail = getEnvOrFallback "NIX_PRIVATE_EMAIL" "bootstrap-alt@example.com" "placeholder-alt@example.com";
    privateUser = getEnvOrFallback "NIX_PRIVATE_USER" "bootstrap-private-user" "placeholder-private-user";
  };

  # Common MCP server configurations
  mcpServers = {
    github = {
      command = "github-mcp-server";
      args = [ "stdio" ];
      env = { GITHUB_PERSONAL_ACCESS_TOKEN = githubMcpToken; };
    };
  };

in
{
  # Export the shared configurations and helpers for use by other modules
  # This allows other modules to import and use these standardized configs
  _module.args = {
    inherit mcpServers githubMcpToken mkHomebrewWrapper sharedIdentity;
  };
}

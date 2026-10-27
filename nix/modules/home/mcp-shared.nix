{ config, lib, pkgs, dotlib, isWorkMachine ? false, ... }:

# Shared MCP (Model Context Protocol) server configurations and helpers
# This module provides common MCP server definitions and utility functions
# that can be reused across different AI coding assistants (Claude, Codex, etc.)

let
  inherit (dotlib) getEnvOrFallback getPersonalEnvOrFallback;
  getPersonalEnv = getPersonalEnvOrFallback isWorkMachine;

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

  # Tokens never pass through Nix (they'd be copied into the world-readable
  # /nix/store): `nx up` writes them to 0600 files here, and consumers read the
  # file at runtime. Must match NIX_SECRETS_DIR in bin/shared
  secretsDir = "${config.home.homeDirectory}/.local/state/nix-secrets";
  secretFile = name: "${secretsDir}/${name}";

  # GitHub MCP token (classic PAT) scopes:
  #   repo, workflow, write:packages, read:packages, write:repo_hook,
  #   read:repo_hook, gist, notifications, read:user, write:discussion,
  #   read:discussion, project, read:project
  #   Manage at: GitHub Settings > Developer settings > Personal access tokens > Tokens (classic)
  githubMcpServer = pkgs.writeShellScript "github-mcp-server" ''
    set -euo pipefail
    token_file=${lib.escapeShellArg (secretFile "github-mcp-token")}
    if [ -r "$token_file" ]; then
      GITHUB_PERSONAL_ACCESS_TOKEN="$(cat "$token_file")"
      export GITHUB_PERSONAL_ACCESS_TOKEN
    fi
    exec ${lib.getExe pkgs.github-mcp-server} "$@"
  '';

  # Shared identity values (centralized to avoid drift between git.nix and ssh.nix)
  sharedIdentity = {
    personalEmail = getEnvOrFallback "NIX_PERSONAL_EMAIL" "bootstrap@example.com" "placeholder@example.com";
    privateEmail = getPersonalEnv "NIX_PRIVATE_EMAIL" "bootstrap-alt@example.com" "placeholder-alt@example.com";
    privateUser = getPersonalEnv "NIX_PRIVATE_USER" "bootstrap-private-user" "placeholder-private-user";
  };

  # Common MCP server configurations
  mcpServers = {
    github = {
      command = "${githubMcpServer}";
      args = [ "stdio" ];
    };
  };

in
{
  # Export the shared configurations and helpers for use by other modules
  # This allows other modules to import and use these standardized configs
  _module.args = {
    inherit mcpServers secretFile mkHomebrewWrapper sharedIdentity;
  };
}

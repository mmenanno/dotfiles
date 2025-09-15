{ config, pkgs, dotlib, ... }:

let
  inherit (dotlib) getEnvOrFallback;
  githubMcpToken = getEnvOrFallback "NIX_GITHUB_MCP_TOKEN" "bootstrap-github-token" "placeholder-github-token";
in
{
  programs.codex = {
    enable = true;
    package = pkgs.codex;

    settings = {
      approval_policy = "on-request";
      sandbox_mode = "workspace-write";
      file_opener = "cursor";
      tools = { web_search = true; };
      mcp_servers = {
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
    };

    custom-instructions = ''
      # User Configuration
      - Prefer object-oriented programming patterns where applicable
      - Use descriptive variable names and clear code structure
      - Minimize external dependencies when possible
      - Always run linting and tests before committing
    '';
  };
}

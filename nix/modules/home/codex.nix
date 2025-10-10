{ config, pkgs, dotlib, mcpServers, ... }:
{
  programs.codex = {
    enable = true;
    package = pkgs.codex;

    settings = {
      approval_policy = "on-request";
      sandbox_mode = "danger-full-access";
      file_opener = "cursor";
      tools = { web_search = true; };
      mcp_servers = mcpServers;
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

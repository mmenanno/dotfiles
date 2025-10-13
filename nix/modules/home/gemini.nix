{ config, pkgs, dotlib, mcpServers, ... }:

{
  programs.gemini-cli = {
    enable = true;
    package = pkgs.gemini-cli;

    settings = {
      ui = {
        theme = "GitHub";
      };

      history_limit = 20;
      max_tokens = 8192;

      security = {
        auth = {
          selectedType = "oauth-personal";
        };
      };

      # MCP server configuration
      mcp_servers = mcpServers;
    };
  };
}


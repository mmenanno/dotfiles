{ config, mcpServers, mkHomebrewWrapper, ... }:

{
  programs.gemini-cli = {
    enable = true;
    # Use Homebrew-installed gemini-cli for faster updates
    package = mkHomebrewWrapper {
      name = "gemini-cli";
      homebrewBinary = "gemini";
      nixBinary = "gemini-cli";
    };

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


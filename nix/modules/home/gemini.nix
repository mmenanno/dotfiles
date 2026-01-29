{ mcpServers, mkHomebrewWrapper, ... }:

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
      general = {
        previewFeatures = true;
      };

      experimental = {
        skills = true;
        plan = true;
      };

      ui = {
        theme = "GitHub";
      };

      history_limit = 20;
      max_tokens = 8192;

      security = {
        enablePermanentToolApproval = true;
        auth = {
          selectedType = "oauth-personal";
        };
      };

      # MCP server configuration
      mcp_servers = mcpServers;
    };
  };
}


{ mcpServers, mkHomebrewWrapper, ... }:
{
  programs.codex = {
    enable = true;
    # Use Homebrew-installed codex for faster updates
    package = mkHomebrewWrapper {
      name = "codex";
      homebrewBinary = "codex";
    };

    settings = {
      approval_policy = "on-request";
      sandbox_mode = "danger-full-access";
      file_opener = "code";
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

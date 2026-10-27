{ mcpServers, ... }:
{
  programs.codex = {
    enable = true;
    # Installed via Homebrew. A null package also tells home-manager to assume
    # the latest Codex; a wrapper with no version selects the legacy
    # config.yaml, which Codex ignores
    package = null;
    # Codex writes its own state (model, trusted projects) to config.toml, so
    # merge the declared settings into it instead of replacing it
    mutableSettings = true;

    settings = {
      approval_policy = "on-request";
      sandbox_mode = "danger-full-access";
      file_opener = "code";
      tools = { web_search = true; };
      mcp_servers = mcpServers;
    };

    context = ''
      # User Configuration
      - Prefer object-oriented programming patterns where applicable
      - Use descriptive variable names and clear code structure
      - Minimize external dependencies when possible
      - Always run linting and tests before committing
    '';
  };
}

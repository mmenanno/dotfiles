_:

{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    # Read from the installed starship package; settings below override it
    presets = [ "nerd-font-symbols" ];
    settings = {
      add_newline = false;

      # Increase timeout for slow git operations
      command_timeout = 2000;  # 2 seconds (default is 500ms)

      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[➜](bold red)";
      };

      directory = {
        truncate_to_repo = true;
      };

      cmd_duration = {
        disabled = true;
      };
    };
  };
}

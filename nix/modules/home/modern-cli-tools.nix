{ pkgs, ... }:

# Modern CLI replacements for traditional Unix tools
# These provide enhanced functionality while maintaining familiar interfaces

{
  # bat - cat with syntax highlighting and git integration
  programs.bat = {
    enable = true;
    config = {
      theme = "TwoDark";
      style = "numbers,changes,header";
    };
    extraPackages = builtins.map (pkg: pkg.overrideAttrs (old: { doCheck = false; })) [
      pkgs.bat-extras.batdiff  # Diff with syntax highlighting
      pkgs.bat-extras.batman   # Man pages with syntax highlighting
      pkgs.bat-extras.batgrep  # Grep with syntax highlighting
    ];
  };

  # Create empty directories to suppress bat cache warnings
  home.file.".config/bat/themes/.keep".text = "";
  home.file.".config/bat/syntaxes/.keep".text = "";

  # eza - modern ls replacement with better defaults
  programs.eza = {
    enable = true;
    git = true;
  };

  # ripgrep - fast grep alternative
  programs.ripgrep = {
    enable = true;
  };

  # direnv - automatic environment switching
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    config = {
      global = {
        load_dotenv = true;
      };
    };
  };

  # atuin - magical shell history
  programs.atuin = {
    enable = true;
    settings = {
      auto_sync = true;
      sync_frequency = "5m";
      search_mode = "fuzzy";
      style = "compact";
      inline_height = 20;
      show_preview = true;
      exit_mode = "return-query";
    };
  };

  # nix-index - locate which package provides a command
  # Configured via nix-index-database flake input for automatic weekly updates
  programs.nix-index.enable = true;

  # fd - modern find alternative (useful with fzf and other tools)
  programs.fd = {
    enable = true;
    hidden = true;
    ignores = [
      ".git/"
      "node_modules/"
      "*.pyc"
    ];
  };
}


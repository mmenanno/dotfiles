{
  # System (nix-darwin) modules: OS, apps, services, defaults
  systemModules = [
    ./system/base-configuration.nix
    ./system/packages.nix
    ./system/homebrew.nix
    ./system/pwa-apps.nix
    ./system/system-defaults.nix
    ./system/rectangle.nix
    ./system/tailscale.nix
    ./system/fonts.nix
    ./system/app-aliases.nix
    ./system/autoclick.nix
  ];

  # Home (Home Manager) modules: user programs, shells, editors, dotfiles
  homeModules = [
    ./home/gh.nix
    ./home/git.nix
    ./home/ruby.nix
    ./home/rails-mcp.nix
    ./home/ssh.nix
    ./home/zsh.nix
    ./home/starship.nix
    ./home/home-manager-system-defaults.nix
    ./home/cursor.nix
    ./home/vscode.nix
    ./home/mise.nix
    ./home/modern-cli-tools.nix
    ./home/onepassword.nix
    ./home/mcp-shared.nix
    ./home/claude.nix
    ./home/codex.nix
    ./home/gemini.nix
    ./home/ide-extensions.nix
    ./home/ai-globals.nix
  ];
}

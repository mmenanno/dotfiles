let
  # Modules shared by both machines; the per-machine lists below only add to these
  commonSystemModules = [
    ./system/base-configuration.nix
    ./system/overlays.nix
    ./system/packages.nix
    ./system/homebrew.nix
    ./system/system-defaults.nix
    ./system/rectangle.nix
    ./system/fonts.nix
  ];

  commonHomeModules = [
    ./home/git.nix
    ./home/ruby.nix
    ./home/ssh.nix
    ./home/zsh.nix
    ./home/starship.nix
    ./home/home-manager-system-defaults.nix
    ./home/vscode.nix
    ./home/mise.nix
    ./home/modern-cli-tools.nix
    ./home/onepassword.nix
    ./home/mcp-shared.nix
    ./home/gh.nix
    ./home/claude.nix
    ./home/claude-skills.nix
    ./home/ide-extensions.nix
    ./home/mutable-files.nix
    ./home/ai-globals.nix
    ./home/tmux.nix
  ];
in
{
  # System (nix-darwin) modules: OS, apps, services, defaults
  systemModules = commonSystemModules ++ [
    ./system/pwa-apps.nix
    ./system/tailscale.nix
    ./system/autoclick.nix
  ];

  # Home (Home Manager) modules: user programs, shells, editors, dotfiles
  homeModules = commonHomeModules ++ [
    ./home/codex.nix
    ./home/gemini.nix
    ./home/torrent-file-icon.nix
  ];

  # Work machine system modules (excludes personal apps/services)
  workSystemModules = commonSystemModules;

  # Work machine home modules
  workHomeModules = commonHomeModules ++ [
    ./home/npmrc.nix
    ./home/rostrum.nix
  ];
}

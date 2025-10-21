{ config, pkgs, ... }:

let
  zshPackages = with pkgs; [
    zinit
  ];
in

{
  home.packages = zshPackages;
  programs.zsh = {
    enable = true;

    initContent = ''
      # Load zinit
      source ${pkgs.zinit}/share/zinit/zinit.zsh

      # Load a few important annexes, without Turbo
      # (this is currently required for annexes)
      zinit light-mode for \
          zdharma-continuum/zinit-annex-as-monitor \
          zdharma-continuum/zinit-annex-bin-gem-node \
          zdharma-continuum/zinit-annex-patch-dl \
          zdharma-continuum/zinit-annex-rust

      # Load all plugins with turbo mode for fastest prompt appearance
      zinit wait lucid light-mode for \
          atload"_zsh_autosuggest_start" \
          zsh-users/zsh-autosuggestions \
          zdharma-continuum/fast-syntax-highlighting \
          zsh-users/zsh-completions \
          Aloxaf/fzf-tab \
          zsh-users/zsh-history-substring-search \
          MichaelAquilina/zsh-you-should-use

      # Add in snippets
      zinit snippet OMZL::git.zsh
      zinit snippet OMZP::git
      zinit snippet OMZP::sudo
      zinit snippet OMZP::extract
      zinit snippet OMZP::copypath
      zinit snippet OMZP::copyfile
      zinit snippet OMZP::brew

      zinit cdreplay -q


      # Add custom shell scripts to path
      export PATH=${config.home.homeDirectory}/dotfiles/bin:$PATH

      # Add custom completions to fpath
      fpath=(${config.home.homeDirectory}/dotfiles/completions $fpath)

      # Initialize zsh completion system
      autoload -Uz compinit
      mkdir -p "$HOME/.cache/zsh"
      compinit -C -d "$HOME/.cache/zsh/compdump"

      # Source dv script to enable 'dv cd' functionality
      source ${config.home.homeDirectory}/dotfiles/bin/dv

      # Source 1Password plugins (managed by home-manager)
      source ${config.home.homeDirectory}/.config/op/plugins.sh

      # Keybindings
      bindkey -e
      bindkey '^p' history-search-backward
      bindkey '^n' history-search-forward
      bindkey '^[w' kill-region

      # History
      HISTDUP=erase
      setopt appendhistory
      setopt sharehistory
      setopt hist_ignore_space
      setopt hist_ignore_all_dups
      setopt hist_save_no_dups
      setopt hist_ignore_dups
      setopt hist_find_no_dups

      # Completion styling
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
      zstyle ':completion:*' menu no
      zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
      zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

      eval "$(pay-respects zsh --alias)"

      # Initialize mise with lazy loading via shims for faster startup
      eval "$(${pkgs.mise}/bin/mise activate zsh --shims)"

      # Initialize zoxide only in interactive shells
      if [[ $- == *i* ]]; then
        eval "$(${pkgs.zoxide}/bin/zoxide init zsh --cmd cd)"
      fi
    '';

    shellAliases = {
      # Modern CLI tool replacements
      cat = "bat";
      grep = "rg";
      find = "fd";

      # Additional convenience aliases
      man = "batman";  # Man pages with syntax highlighting
      diff = "batdiff";  # Diffs with syntax highlighting
      c = "cursor .";  # Open Cursor in current directory
    };

    sessionVariables = {
      EDITOR = "cursor --wait";

      # Claude Code configuration
      DISABLE_TELEMETRY = "false";
      DISABLE_ERROR_REPORTING = "false";
      CLAUDE_CODE_DISABLE_TERMINAL_TITLE = "false";
      BASH_DEFAULT_TIMEOUT_MS = "120000";

      # Homebrew configuration
      HOMEBREW_NO_ANALYTICS = "1";
      HOMEBREW_NO_UPDATE_REPORT_NEW = "1";

      # Zoxide configuration
      _ZO_DOCTOR = "0";  # Disable zoxide doctor warnings
    };
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    # Disable automatic integration to prevent errors in non-interactive shells
    enableZshIntegration = false;
    options = [
      "--cmd cd"
    ];
  };

}

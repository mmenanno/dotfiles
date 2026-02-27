{ config, pkgs, ... }:

let
  zshPackages = [
    pkgs.zinit
  ];
in

{
  home.packages = zshPackages;

  programs = {
    zsh = {
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

      # Ensure zinit completions cache exists for plugins that generate completions
      mkdir -p "$HOME/.cache/zinit/completions"

      # Add in snippets
      zinit snippet OMZL::git.zsh
      zinit snippet OMZP::git
      zinit snippet OMZP::sudo
      zinit snippet OMZP::extract
      zinit snippet OMZP::copypath
      zinit snippet OMZP::copyfile
      zinit snippet OMZP::brew
      zinit snippet OMZP::bundler
      zinit snippet OMZP::docker
      zinit snippet OMZP::gh
      zinit snippet OMZP::iterm2

      zinit cdreplay -q


      # Add custom shell scripts to path
      export PATH=${config.home.homeDirectory}/.local/bin:${config.home.homeDirectory}/dotfiles/bin:$PATH

      # Add custom completions to fpath
      fpath=(${config.home.homeDirectory}/dotfiles/completions $fpath)

      # Initialize zsh completion system
      autoload -Uz compinit
      mkdir -p "$HOME/.cache/zsh"
      compinit -C -d "$HOME/.cache/zsh/compdump"

      # Source dv script to enable 'dv cd' functionality
      [[ -f ${config.home.homeDirectory}/dotfiles/bin/dv ]] && source ${config.home.homeDirectory}/dotfiles/bin/dv

      # Source 1Password plugins (managed by home-manager)
      [[ -f ${config.home.homeDirectory}/.config/op/plugins.sh ]] && source ${config.home.homeDirectory}/.config/op/plugins.sh

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

      # Disable fzf-tab for dv command to avoid visual glitches - use standard completion
      zstyle ':fzf-tab:complete:dv:*' disabled-on 1

      eval "$(pay-respects zsh --alias)"

      # Initialize mise with lazy loading via shims for faster startup
      eval "$(${pkgs.mise}/bin/mise activate zsh --shims)"

      # Initialize zoxide only in interactive shells
      if [[ $- == *i* ]]; then
        eval "$(${pkgs.zoxide}/bin/zoxide init zsh --cmd cd)"
      fi

      # Auto-list directory contents on cd
      chpwd() { eza --icons --group-directories-first; }
    '';

    shellAliases = {
      # Modern CLI tool replacements
      grep = "rg";
      find = "fd";

      # Additional convenience aliases
      man = "batman";  # Man pages with syntax highlighting
      diff = "batdiff";  # Diffs with syntax highlighting
      c = "code .";  # Open VS Code in current directory
      ".." = "cd ..";
      "..." = "cd $(git rev-parse --show-toplevel)";
      allow = "allow-app";  # Quick alias for removing quarantine flags
      wrangler = "npx wrangler";  # Avoid slow Nix source build
    };

    sessionVariables = {
      EDITOR = "code --wait";

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

      # Font directories for XeLaTeX/fontconfig (system + Nix-managed fonts)
      OSFONTDIR = "/System/Library/Fonts/Supplemental:/Library/Fonts:/Library/Fonts/Nix Fonts:$HOME/Library/Fonts";
    };
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
    };

    zoxide = {
      enable = true;
      # Disable automatic integration to prevent errors in non-interactive shells
      enableZshIntegration = false;
      options = [
        "--cmd cd"
      ];
    };
  };
}

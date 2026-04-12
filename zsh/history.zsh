# Shared history-suggestion logic. Sourced from:
#   - nix/modules/home/zsh.nix   (installs live hook + autosuggest strategy)
#   - bin/zsh-hist-clean         (retroactive cleanup of ~/.zsh_history)
#
# Goals:
#   - Suggestions skip one-off command lines (paths, prompts, commit messages).
#   - HISTFILE stays clean so new sessions load already-filtered history.
#   - Atuin continues to own Ctrl+R and keeps full originals for search.

# ---- Classifier ------------------------------------------------------------
# Return 0 if a token looks like a throwaway arg (path, quoted blob, URL,
# opaque long string). Return 1 otherwise.
_zhist_noisy() {
  local t=$1
  [[ $t == \"*\" || $t == \'*\' ]] && return 0
  [[ $t == http://* || $t == https://* || $t == git@*:* ]] && return 0
  local slashes=${t//[^\/]/}
  (( ${#slashes} >= 4 )) && return 0
  (( ${#t} > 40 )) && return 0
  return 1
}

# Classify a command line. Sets global REPLY to one of:
#   KEEP                — line is fine to keep/suggest
#   DROP                — discard entirely (e.g. cd; zoxide owns these)
#   REWRITE<TAB><new>   — replace with <new>
# Uses REPLY instead of stdout so callers can avoid command-substitution
# subshells on hot paths (autosuggest strategy runs per keystroke).
_zhist_classify() {
  emulate -L zsh
  REPLY=KEEP
  local line=${1%%$'\n'}
  [[ $line == *[\|\&\;\<\>]* ]] && return
  local -a parts=(${(z)line})
  (( ${#parts} < 2 )) && return

  local cmd=$parts[1]
  local rewritten=""
  case $cmd in
    cd) REPLY=DROP; return ;;
    rm)
      local kept="rm" p
      for p in ${parts[2,-1]}; do
        [[ $p == -* ]] && kept+=" $p" || break
      done
      rewritten=$kept
      ;;
    ren|claude|open|git|g)
      local kept=$cmd p
      for p in ${parts[2,-1]}; do
        if _zhist_noisy $p; then break; fi
        kept+=" $p"
      done
      rewritten=$kept
      ;;
    *) return ;;
  esac

  if [[ -n $rewritten && $rewritten != $line ]]; then
    REPLY="REWRITE	$rewritten"
  fi
}

# ---- Live integration (interactive shells only) ----------------------------
if [[ -o interactive ]]; then
  autoload -Uz add-zsh-hook

  # Custom autosuggestions strategy: walk $history newest→oldest, return the
  # first entry that (a) has the typed prefix and (b) the classifier says
  # is clean (KEEP). This bypasses any $history pollution from zshaddhistory
  # return-code quirks and makes suggestions authoritative via the classifier.
  _zsh_autosuggest_strategy_clean_history() {
    emulate -L zsh
    setopt EXTENDED_GLOB
    # Escape glob metacharacters in the typed prefix so it's matched literally.
    local prefix=${1//(#m)[\\()\[\]|*?~^]/\\$MATCH}
    # ${history[@]} iterates values newest-first. Indexing via numeric keys
    # would be wrong — $history is an associative array keyed by event number,
    # and those keys don't start at 1.
    local entry
    for entry in "${history[@]}"; do
      [[ $entry == $~prefix* ]] || continue
      _zhist_classify "$entry"
      [[ $REPLY == KEEP ]] && { typeset -g suggestion=$entry; return }
    done
  }

  # atuin init (runs later in .zshrc) sets strategy to (atuin). Override on
  # first prompt so our strategy wins. Atuin still owns Ctrl+R.
  _fix_autosuggest_strategy() {
    ZSH_AUTOSUGGEST_STRATEGY=(clean_history)
    add-zsh-hook -d precmd _fix_autosuggest_strategy
  }
  add-zsh-hook precmd _fix_autosuggest_strategy

  # zshaddhistory: primarily keeps HISTFILE clean. Even if $history retains
  # the original in memory due to zsh's return-code semantics, the custom
  # strategy above filters suggestions by classifier — so visible behavior is
  # correct regardless.
  zshaddhistory() {
    _zhist_classify "$1"
    case $REPLY in
      DROP) return 1 ;;
      REWRITE*)
        print -sr -- ${REPLY#REWRITE	}
        return 1
        ;;
      *) return 0 ;;
    esac
  }
fi

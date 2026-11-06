[[ $- != *i* ]] && return

# Its layout needs about this many columns, and garbles in anything narrower.
((COLUMNS >= 90)) && fastfetch

# History
HISTSIZE=32768
SAVEHIST=$HISTSIZE
HISTFILE="$HOME/.zsh_history"
setopt APPEND_HISTORY HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS

# Completion
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Up and down match what you've typed so far against history.
bindkey "^[[A" history-beginning-search-backward
bindkey "^[[B" history-beginning-search-forward

# Tools
eval "$(mise activate zsh)"
[[ ${TERM:-} != dumb ]] && eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
# 2>/dev/null: this fzf and zsh combination prints a harmless "can't change option: zle".
source /usr/share/fzf/completion.zsh 2>/dev/null
source /usr/share/fzf/key-bindings.zsh 2>/dev/null
eval "$(atuin init zsh)"

# Files
alias ls='eza -lh --group-directories-first --icons=auto'
alias lsa='ls -a'
alias lt='eza --tree --level=2 --long --icons --git'
alias lta='lt -a'
alias ff="fzf --preview 'bat --style=numbers --color=always {}'"
alias eff='$EDITOR "$(ff)"'
open() { xdg-open "$@" >/dev/null 2>&1 & }

# Directories: cd falls back to zoxide when the path doesn't exist.
alias cd="zd"
zd() {
  if (($# == 0)); then
    builtin cd ~ || return
  elif [[ -d $1 ]]; then
    builtin cd "$1" || return
  else
    z "$@" && pwd
  fi
}
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Tools
alias hx='helix'
alias n='nvim'
alias d='docker'
alias g='git'
alias gcm='git commit -m'
alias gcam='git commit -a -m'
alias gcad='git commit -a --amend'
alias t='tmux attach || tmux new -s Work'
alias h='herdr'
alias cx='claude --permission-mode auto'

# superfile: cd to its last directory on quit.
spf() {
  export SPF_LAST_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/superfile/lastdir"
  command spf "$@"
  if [[ -f $SPF_LAST_DIR ]]; then
    . "$SPF_LAST_DIR"
    rm -f -- "$SPF_LAST_DIR" >/dev/null
  fi
}

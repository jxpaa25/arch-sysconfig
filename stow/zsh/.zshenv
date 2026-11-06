# Read by every zsh, including non-interactive ones.
typeset -U path
path=("$HOME/.local/bin" "$HOME/.cargo/bin" $path)
export PATH

export EDITOR=helix
export SUDO_EDITOR=helix
export BROWSER=launch-browser
export BAT_THEME=ansi
export MANROFFOPT="-c"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

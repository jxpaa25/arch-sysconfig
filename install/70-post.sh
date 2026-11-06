#!/usr/bin/env bash
# Things that need the packages and dotfiles to be in place.
set -euo pipefail
# shellcheck source=install/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# The overview is optional, so a failed build mustn't stop the install.
if [[ ! -e $HOME/.local/src/hyprexpo/hyprexpo.so ]]; then
  info "Building hyprexpo"
  "$REPO_DIR/stow/scripts/.local/bin/hyprexpo-rebuild" ||
    warn "hyprexpo didn't build. The desktop works without it. Retry with hyprexpo-rebuild."
fi

# Apps rewrite these at runtime, so they get a copy, not a link into the repo.
config="${XDG_CONFIG_HOME:-$HOME/.config}"
[[ -e $config/mimeapps.list ]] || cp "$REPO_DIR/templates/mimeapps.list" "$config/mimeapps.list"
[[ -e $config/nvim/lazyvim.json ]] || cp "$REPO_DIR/templates/lazyvim.json" "$config/nvim/lazyvim.json"

# Also creates the links the rest of the config expects to find.
if [[ ! -e $HOME/.local/state/theme/current ]]; then
  info "Setting the default theme"
  "$REPO_DIR/stow/scripts/.local/bin/theme-set" vantablack
fi

if ! herdr plugin list 2>/dev/null | grep -q space-scoped-agents; then
  info "Linking the herdr plugin"
  herdr plugin link "$config/herdr/plugins/space-scoped-agents" ||
    warn "The herdr plugin didn't link. Retry with: herdr plugin link $config/herdr/plugins/space-scoped-agents"
fi

# Install LazyVim's plugins now, so the first launch doesn't stop for it.
if [[ ! -d $HOME/.local/share/nvim/lazy/LazyVim ]]; then
  info "Installing Neovim plugins"
  nvim --headless "+Lazy! restore" +qa >/dev/null 2>&1 || nvim --headless "+Lazy! sync" +qa ||
    warn "Neovim plugins didn't install. They install on the first launch instead."
fi

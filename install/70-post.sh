#!/usr/bin/env bash
# Things built from source.
set -euo pipefail
# shellcheck source=install/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# The overview is optional, so a failed build mustn't stop the install.
if [[ ! -e $HOME/.local/src/hyprexpo/hyprexpo.so ]]; then
  info "Building hyprexpo"
  "$REPO_DIR/stow/scripts/.local/bin/hyprexpo-rebuild" ||
    warn "hyprexpo didn't build. The desktop works without it. Retry with hyprexpo-rebuild."
fi

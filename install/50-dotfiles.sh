#!/usr/bin/env bash
# Link every package in stow/ into $HOME. Files already there are moved to a backup,
# never overwritten.
set -euo pipefail
# shellcheck source=install/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

backup_dir="$STATE_DIR/backup-$(date +%Y%m%d-%H%M%S)"

for pkg_dir in "$REPO_DIR"/stow/*/; do
  pkg="$(basename "$pkg_dir")"

  while IFS= read -r -d '' file; do
    rel="${file#"$pkg_dir"}"
    target="$HOME/$rel"
    if [[ -e $target || -L $target ]] && [[ ! $target -ef $file ]]; then
      mkdir -p "$(dirname "$backup_dir/$rel")"
      mv "$target" "$backup_dir/$rel"
      info "Moved ~/$rel to $backup_dir"
    fi
  done < <(find "$pkg_dir" -type f -print0)

  # --no-folding links files, not directories, so that apps writing runtime files
  # next to their config don't end up writing them into this repo.
  stow --dir "$REPO_DIR/stow" --target "$HOME" --no-folding --restow "$pkg"
done

# Themes and templates are read by theme-set at runtime, so link them rather than stow them.
mkdir -p "$HOME/.local/share/desk"
ln -sfn "$REPO_DIR/themes" "$HOME/.local/share/desk/themes"
ln -sfn "$REPO_DIR/templates" "$HOME/.local/share/desk/templates"

# git config --global writes to ~/.gitconfig when it exists, and otherwise to the stowed
# ~/.config/git/config, where your identity would end up in this repo. Both get read.
touch "$HOME/.gitconfig"

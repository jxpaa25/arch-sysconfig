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

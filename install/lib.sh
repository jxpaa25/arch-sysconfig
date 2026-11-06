#!/usr/bin/env bash
# Shared helpers, sourced by install.sh and every module.

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/arch-sysconfig"
INITRAMFS_FLAG="$STATE_DIR/initramfs-dirty"
mkdir -p "$STATE_DIR"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m==> WARNING:\033[0m %s\n' "$*" >&2; }
die() {
  printf '\033[1;31m==> ERROR:\033[0m %s\n' "$*" >&2
  exit 1
}

# Print a package list, without comments or blank lines.
read_list() {
  sed -E 's/#.*//; s/[[:space:]]+//g; /^$/d' "$REPO_DIR/packages/$1.txt"
}

# Install the repo packages from one or more lists in packages/.
install_pkgs() {
  local list pkgs=()
  for list in "$@"; do
    mapfile -t -O "${#pkgs[@]}" pkgs < <(read_list "$list")
  done
  ((${#pkgs[@]})) || return 0
  sudo pacman -S --needed --noconfirm -- "${pkgs[@]}"
}

# Install AUR packages from one or more lists, removing build-only tools afterwards.
install_aur() {
  local list pkgs=()
  for list in "$@"; do
    mapfile -t -O "${#pkgs[@]}" pkgs < <(read_list "$list")
  done
  ((${#pkgs[@]})) || return 0
  yay -S --needed --noconfirm --removemake --answerclean None --answerdiff None -- "${pkgs[@]}"
}

# Note that the initramfs has to be rebuilt once the current run finishes.
mark_initramfs_dirty() {
  touch "$INITRAMFS_FLAG"
}

# Copy system/<tree>/etc into /etc. Only changed files are touched, so reruns are
# no-ops. Sets TREE_CHANGED to 1 when anything was written.
install_tree() {
  local tree="$REPO_DIR/system/$1/etc" src rel
  # shellcheck disable=SC2034  # read by the calling module
  TREE_CHANGED=0
  while IFS= read -r -d '' src; do
    rel="${src#"$tree"/}"
    if ! sudo cmp -s "$src" "/etc/$rel"; then
      sudo install -D -m 644 "$src" "/etc/$rel"
      info "Installed /etc/$rel"
      # shellcheck disable=SC2034  # read by the calling module
      TREE_CHANGED=1
      case "$rel" in
        modprobe.d/* | mkinitcpio.conf.d/*) mark_initramfs_dirty ;;
      esac
    fi
  done < <(find "$tree" -type f -print0 | sort -z)
}

# Rebuild the initramfs if a module asked for it. Prefers limine-update, which also
# refreshes the boot entries. Calls /usr/bin/mkinitcpio directly, because
# limine-mkinitcpio-hook's wrapper in /usr/local/bin prompts interactively.
rebuild_initramfs_if_needed() {
  [[ -e $INITRAMFS_FLAG ]] || return 0
  info "Rebuilding the initramfs"
  if command -v limine-update >/dev/null; then
    sudo limine-update
  else
    sudo /usr/bin/mkinitcpio -P
  fi
  rm -f "$INITRAMFS_FLAG"
}

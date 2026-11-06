#!/usr/bin/env bash
# Bootstrap the yay AUR helper.
set -euo pipefail
# shellcheck source=install/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

if command -v yay >/dev/null; then
  info "yay is already installed"
  exit 0
fi

info "Building yay-bin from the AUR"
build_dir="$(mktemp -d)"
trap 'rm -rf "$build_dir"' EXIT
git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$build_dir/yay-bin"
(cd "$build_dir/yay-bin" && makepkg -si --noconfirm --needed)

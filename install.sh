#!/usr/bin/env bash
# Takes a fresh Arch install (see docs/step-0-install.md) to the full desktop.
# Safe to rerun: every module only changes what isn't already in place.
#
#   ./install.sh                 run all modules, in order
#   ./install.sh --only <name>   run one module, e.g. --only drivers or --only 20-drivers
#   ./install.sh --list          list the modules
set -euo pipefail

# shellcheck source=install/lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/install/lib.sh"

MODULES=(10-base 20-drivers 30-aur 35-snapshots)

usage() {
  sed -n '2,7s/^# \{0,1\}//p' "${BASH_SOURCE[0]}"
}

selected=("${MODULES[@]}")
case "${1:-}" in
  "") ;;
  --list)
    printf '%s\n' "${MODULES[@]}"
    exit 0
    ;;
  --only)
    [[ -n ${2:-} ]] || die "--only needs a module name. See --list."
    selected=()
    for module in "${MODULES[@]}"; do
      if [[ $module == "$2" || ${module#*-} == "$2" ]]; then
        selected=("$module")
      fi
    done
    ((${#selected[@]})) || die "Unknown module: $2. See --list."
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac

[[ $EUID -ne 0 ]] || die "Run this as your normal user. It asks for sudo when it needs to."
[[ -e /etc/arch-release ]] || die "This only supports Arch Linux."
curl -fsS --max-time 15 -o /dev/null https://archlinux.org || die "No network connection."

log="$STATE_DIR/install-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$log") 2>&1
info "Logging to $log"

# Ask for sudo once, and keep it alive through long AUR builds.
sudo -n true 2>/dev/null || sudo -v
while sudo -n true 2>/dev/null; do
  sleep 60
done &
keepalive=$!
trap 'kill "$keepalive" 2>/dev/null || true' EXIT

for module in "${selected[@]}"; do
  info "Module: $module"
  bash "$REPO_DIR/install/$module.sh"
done

rebuild_initramfs_if_needed

info "Done. Reboot to apply everything."

#!/usr/bin/env bash
# pacman settings, base packages and system tuning.
set -euo pipefail
# shellcheck source=install/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

info "Configuring pacman"
sudo sed -i -E 's/^#(Color|VerbosePkgLists)$/\1/; s/^#?ParallelDownloads.*/ParallelDownloads = 5/' /etc/pacman.conf
grep -q '^ILoveCandy$' /etc/pacman.conf || sudo sed -i '/^Color$/a ILoveCandy' /etc/pacman.conf

info "Updating the system"
sudo pacman -Syu --noconfirm

install_pkgs base

info "Installing system tuning"
install_tree common
sudo systemctl daemon-reload

# A kernel update above can leave the running kernel without its modules. These apply
# at the next boot anyway, so a failure here isn't fatal.
sudo sysctl --system >/dev/null || warn "Some sysctls failed. They apply after a reboot."
sudo systemd-tmpfiles --create --boot /etc/tmpfiles.d/zswap.conf ||
  warn "zswap setting failed. It applies after a reboot."
sudo systemctl start systemd-zram-setup@zram0.service ||
  warn "zram didn't start. It starts after a reboot."

sudo systemctl enable --now fstrim.timer systemd-timesyncd.service systemd-oomd.service

info "Switching DNS to systemd-resolved"
sudo systemctl enable --now systemd-resolved.service
stub=/run/systemd/resolve/stub-resolv.conf
if [[ $(readlink /etc/resolv.conf || true) != "$stub" ]]; then
  sudo ln -sf "$stub" /etc/resolv.conf
  sudo systemctl try-restart NetworkManager.service
fi

# logind settings apply at the next boot. Restarting logind can end a running session.

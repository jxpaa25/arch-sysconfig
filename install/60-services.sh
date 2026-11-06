#!/usr/bin/env bash
# Default shell, Docker, Bluetooth and the firewall.
set -euo pipefail
# shellcheck source=install/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

if [[ $(getent passwd "$USER" | cut -d: -f7) != /usr/bin/zsh ]]; then
  info "Setting zsh as the login shell"
  sudo usermod --shell /usr/bin/zsh "$USER"
fi

# With no display manager, nothing else unlocks the keyring at login, and apps such as
# Chromium would keep asking for its password. "optional" means these can't block a login.
if ! grep -q pam_gnome_keyring /etc/pam.d/login; then
  info "Unlocking gnome-keyring at login"
  sudo sed -i \
    -e '/^auth .*include .*system-local-login/a auth       optional     pam_gnome_keyring.so' \
    -e '/^session .*include .*system-local-login/a session    optional     pam_gnome_keyring.so auto_start' \
    /etc/pam.d/login
fi
if ! grep -q pam_gnome_keyring /etc/pam.d/passwd; then
  # Keep the keyring's password the same as the login password when it changes.
  printf 'password   optional     pam_gnome_keyring.so\n' | sudo tee -a /etc/pam.d/passwd >/dev/null
fi

info "Configuring Docker"
install_tree docker
if ((TREE_CHANGED)); then
  sudo systemctl try-restart systemd-resolved.service
  sudo systemctl try-restart docker.service
fi
sudo systemctl enable --now docker.service
# Equivalent to passwordless root, but lets lazydocker and docker work without sudo.
if ! id -nG "$USER" | grep -qw docker; then
  sudo usermod --append --groups docker "$USER"
  info "Added $USER to the docker group. This applies at the next login."
fi

# Starts only when a Bluetooth adapter exists.
sudo systemctl enable --now bluetooth.service

info "Configuring the firewall"
sudo ufw default deny incoming
sudo ufw default allow outgoing
# Don't lock anyone out of a machine they reach over SSH.
if systemctl is-enabled --quiet sshd.service 2>/dev/null; then
  sudo ufw allow 22/tcp comment 'ssh'
fi
sudo ufw allow in proto udp from 172.16.0.0/12 to 172.17.0.1 port 53 comment 'allow-docker-dns'
sudo ufw allow in proto udp from 192.168.0.0/16 to 172.17.0.1 port 53 comment 'allow-docker-dns'
sudo ufw --force enable
sudo systemctl enable ufw.service

# Docker bypasses ufw by default, which leaves published ports open to the network.
if ! sudo grep -q 'BEGIN UFW AND DOCKER' /etc/ufw/after.rules; then
  sudo ufw-docker install
  sudo ufw reload
fi

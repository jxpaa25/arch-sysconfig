#!/usr/bin/env bash
# Detect the machine and install matching graphics drivers, microcode and firmware.
set -euo pipefail
# shellcheck source=install/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# Print the vendor ID of every display controller. Reads sysfs, because lspci would
# wake a suspended discrete GPU and pciutils isn't installed.
gpu_vendors() {
  local dev
  for dev in /sys/bus/pci/devices/*; do
    if [[ $(<"$dev/class") == 0x03* ]]; then
      cat "$dev/vendor"
    fi
  done
}

install_pkgs gpu-common

mapfile -t vendors < <(gpu_vendors | sort -u)
info "Display controller vendors: ${vendors[*]:-none}"

for vendor in "${vendors[@]}"; do
  case "$vendor" in
    0x8086) install_pkgs gpu-intel ;;
    0x1002) install_pkgs gpu-amd ;;
    0x10de)
      warn "Installing NVIDIA drivers. This path is untested until it runs on real hardware."
      install_pkgs gpu-nvidia
      install_tree nvidia
      ;;
    0x1af4 | 0x1234 | 0x1b36 | 0x15ad) info "Virtual GPU, mesa covers it" ;;
    *) warn "Unknown GPU vendor $vendor, using mesa only" ;;
  esac
done

virt="$(systemd-detect-virt || true)"
info "Virtualization: $virt"

case "$virt" in
  none)
    install_pkgs hardware
    case "$(awk -F': ' '/^vendor_id/ { print $2; exit }' /proc/cpuinfo)" in
      GenuineIntel) install_pkgs cpu-intel ;;
      AuthenticAMD) install_pkgs cpu-amd ;;
      *) warn "Unknown CPU vendor, skipping microcode" ;;
    esac
    ;;
  kvm | qemu)
    install_pkgs vm-qemu
    # Can't be enabled: it starts on demand when its virtio channel appears.
    # Start it now as well, so it works before the next boot.
    sudo systemctl start qemu-guest-agent.service || warn "qemu-guest-agent didn't start"
    ;;
  *)
    info "Not a QEMU guest, no guest tools to install"
    ;;
esac

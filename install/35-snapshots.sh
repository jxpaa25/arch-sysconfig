#!/usr/bin/env bash
# Bootable system snapshots: snapper, with Limine entries kept in sync.
# Skipped unless the root filesystem is btrfs and the bootloader is Limine.
set -euo pipefail
# shellcheck source=install/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# sudo: /boot is usually readable by root only.
if [[ $(findmnt -no FSTYPE /) != btrfs ]] || ! sudo test -e /boot/limine.conf; then
  warn "Root isn't btrfs on Limine, skipping bootable snapshots"
  exit 0
fi

# Record the running kernel command line, which holds the LUKS and subvolume settings.
# limine-entry-tool reads it from here when it writes boot entries.
if [[ ! -s /etc/kernel/cmdline ]]; then
  cmdline="$(tr ' ' '\n' </proc/cmdline | grep -vE '^(BOOT_IMAGE|initrd)=' | paste -sd' ')"
  [[ $cmdline == *root=* ]] || die "No root= in the kernel command line: $cmdline"
  [[ $cmdline != *.snapshots* ]] || die "Booted from a snapshot. Restore it before running this."
  sudo install -d -m 755 /etc/kernel
  printf '%s\n' "$cmdline" | sudo tee /etc/kernel/cmdline >/dev/null
  info "Saved the kernel command line to /etc/kernel/cmdline"
  mark_initramfs_dirty
fi

install_tree snapshots
if ((TREE_CHANGED)); then
  mark_initramfs_dirty
fi

install_pkgs snapshots

# The GraalVM and Gradle builds leave about 700 MB behind. Remove it, without touching
# a ~/.gradle that was already there before this build.
[[ -e $HOME/.gradle ]] && had_gradle=1 || had_gradle=0
# No Gradle daemon: it would outlive the build, keep writing to ~/.gradle, and keep
# holding memory for hours after yay has uninstalled its JDK.
GRADLE_OPTS="-Dorg.gradle.daemon=false" install_aur aur-snapshots
rm -rf "$HOME"/.cache/yay/limine-mkinitcpio-hook "$HOME"/.cache/yay/limine-snapper-sync
if ((!had_gradle)); then
  pkill -u "$USER" -f GradleDaemon || true
  rm -rf "$HOME/.gradle"
fi

# limine-mkinitcpio-hook deploys the EFI binaries itself, which replaces the hook from Step 0.
sudo rm -f /etc/pacman.d/hooks/99-limine.hook

# Booting a read-only snapshot needs an overlay. Which hook depends on the initramfs type.
hooks="$(grep -E '^HOOKS=' /etc/mkinitcpio.conf)"
if [[ " ${hooks//[()]/ } " == *" systemd "* ]]; then
  overlay_hook=sd-btrfs-overlayfs
else
  overlay_hook=btrfs-overlayfs
fi
if [[ " ${hooks//[()]/ } " != *" $overlay_hook "* ]]; then
  sudo sed -i -E "/^HOOKS=/ s/\bfilesystems\b/filesystems $overlay_hook/" /etc/mkinitcpio.conf
  info "Added $overlay_hook to the initramfs hooks"
  mark_initramfs_dirty
fi

if ! sudo snapper --no-dbus list-configs | grep -q '^root\b'; then
  info "Creating the snapper config for /"
  sudo snapper --no-dbus -c root create-config /
fi
# Keep the last few snapshots from package operations. No hourly timeline.
sudo snapper --no-dbus -c root set-config \
  NUMBER_CLEANUP=yes NUMBER_MIN_AGE=0 NUMBER_LIMIT=5 NUMBER_LIMIT_IMPORTANT=5 TIMELINE_CREATE=no

sudo systemctl disable --now snapper-timeline.timer 2>/dev/null || true
# limine-snapper-sync.service exits straight away without inotify-tools, handing over to
# its snapper plugin, which is enough. "inactive" is its normal state here.
sudo systemctl enable --now snapper-cleanup.timer limine-snapper-sync.service

conf=/boot/limine.conf

# Without this, Limine opens on the "Arch Linux" heading, which can't boot, so the menu
# waits forever instead of counting down. An entry path survives menu layout changes.
set_default_entry() {
  if ! sudo grep -q '^default_entry:' "$conf"; then
    sudo sed -i '1a default_entry: Arch Linux/linux' "$conf"
    info "Set the default boot entry"
  fi
}

# Replace the hand-written Step 0 boot entry with generated ones. limine-update keeps an
# existing entry and nests its own under it, so it needs an empty config to start from.
# Restore the old one on any failure: this file decides whether the machine boots.
if sudo grep -qF 'boot():/vmlinuz-linux' "$conf"; then
  info "Generating the Limine boot entries"
  sudo cp "$conf" "$conf.step0"
  printf 'timeout: 3\n' | sudo tee "$conf" >/dev/null
  set_default_entry
  if ! sudo limine-update || ! sudo grep -q 'kernel-id=linux' "$conf"; then
    sudo cp "$conf.step0" "$conf"
    die "limine-update failed. Restored the previous $conf."
  fi
  rm -f "$INITRAMFS_FLAG"
  sudo rm -f "$conf.step0" /boot/vmlinuz-linux /boot/initramfs-linux.img /boot/EFI/limine/BOOTX64.EFI

  # limine-update registered its own UEFI entry. Remove the Step 0 one, which is now dead.
  sudo efibootmgr | sed -nE 's/^Boot([0-9A-F]{4})\*?.*\\EFI\\limine\\BOOTX64\.EFI.*/\1/p' |
    while read -r entry; do
      sudo efibootmgr --quiet --bootnum "$entry" --delete-bootnum
    done
fi
set_default_entry

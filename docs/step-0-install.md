# Step 0: Installing base Arch

This is the exact base install that `install.sh` expects to start from. `install.sh` itself
never partitions disks. Commands below ran in a libvirt VM; see
[Differences on real hardware](#differences-on-real-hardware) for bare metal.

Result: LUKS2 + btrfs (`@`, `@home`, `@log`, `@pkg`), Limine, stock `linux`, 10 explicit packages.

## 1. Create the VM (host)

```bash
mkdir -p ~/VMs/images && chmod 700 ~/VMs/images && cd ~/VMs/images

# Download the ISO, its checksums and its signature (2026.11.01 at the time of writing)
curl -fLO https://geo.mirror.pkgbuild.com/iso/2026.11.01/archlinux-2026.11.01-x86_64.iso
curl -fLO https://archlinux.org/iso/2026.11.01/archlinux-2026.11.01-x86_64.iso.sig
curl -fL https://archlinux.org/iso/2026.11.01/sha256sums.txt -o sha256sums.txt

# Verify, using a throwaway keyring so your own stays untouched
grep ' archlinux-2026.11.01-x86_64.iso$' sha256sums.txt | sha256sum -c -
export GNUPGHOME="$(mktemp -d)"
gpg --auto-key-locate clear,wkd --locate-external-key pierre@archlinux.org
gpg --verify archlinux-2026.11.01-x86_64.iso.sig archlinux-2026.11.01-x86_64.iso
unset GNUPGHOME

# VM-only SSH key, with no passphrase, useful for reaching this VM and nothing else
ssh-keygen -t ed25519 -N '' -C arch-vm-dev -f ~/.ssh/arch-vm_ed25519

virt-install --connect qemu:///session \
  --name arch-vm --osinfo archlinux --vcpus 4 --memory 6144 \
  --disk path="$HOME/VMs/images/arch-vm.qcow2",size=80,format=qcow2,bus=virtio,discard=unmap \
  --cdrom "$HOME/VMs/images/archlinux-2026.11.01-x86_64.iso" \
  --boot uefi,firmware.feature0.name=secure-boot,firmware.feature0.enabled=no \
  --video virtio,model.acceleration.accel3d=yes \
  --graphics spice,listen=none,gl.enable=yes,gl.rendernode=/dev/dri/renderD129 \
  --network type=user,backend.type=passt,model=virtio,portForward0.proto=tcp,portForward0.range0.start=2222,portForward0.range0.to=22 \
  --cloud-init root-ssh-key="$HOME/.ssh/arch-vm_ed25519.pub" \
  --noautoconsole
```

Notes:

- `qemu:///session` runs as your own user, so no host sudo or ACL changes are needed, even with a `0700` home.
- `gl.rendernode` must be the Intel GPU on a hybrid laptop. Find it with `ls -l /dev/dri/by-path/`; the
  number can differ between machines.
- `--cloud-init` loads the SSH key into the live ISO, so no root password is needed there.
- Reach the live ISO with `dev/vm-ssh.sh --live`. Everything in steps 2-4 runs there, as root.

## 2. Disk

```bash
sgdisk --zap-all /dev/vda
sgdisk -n1:0:+2G -t1:ef00 -c1:ESP -n2:0:0 -t2:8309 -c2:cryptroot /dev/vda
mkfs.fat -F32 -n ESP /dev/vda1

cryptsetup luksFormat --type luks2 /dev/vda2
cryptsetup open --allow-discards --persistent /dev/vda2 root

mkfs.btrfs -f -L arch /dev/mapper/root
mount /dev/mapper/root /mnt
for s in @ @home @log @pkg; do btrfs subvolume create /mnt/$s; done
umount /mnt

O=noatime,compress=zstd:1
mount -o $O,subvol=@ /dev/mapper/root /mnt
mkdir -p /mnt/{home,boot,var/log,var/cache/pacman/pkg}
mount -o $O,subvol=@home /dev/mapper/root /mnt/home
mount -o $O,subvol=@log /dev/mapper/root /mnt/var/log
mount -o $O,subvol=@pkg /dev/mapper/root /mnt/var/cache/pacman/pkg
mount -o fmask=0077,dmask=0077 /dev/vda1 /mnt/boot
```

`--allow-discards` lets TRIM pass through LUKS, which keeps the sparse VM image small. On real
hardware it reveals which blocks are unused, which is a minor trade-off.

## 3. Base packages

```bash
pacstrap -K /mnt base linux mkinitcpio btrfs-progs dosfstools limine efibootmgr networkmanager openssh sudo
genfstab -U /mnt > /mnt/etc/fstab
sed -i -E 's/,subvolid=[0-9]+//' /mnt/etc/fstab   # keeps subvol= only, so snapshot rollback stays valid
```

## 4. Configure (`arch-chroot /mnt`)

```bash
ln -sf /usr/share/zoneinfo/Europe/Belgrade /etc/localtime
hwclock --systohc
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf
echo 'KEYMAP=us' > /etc/vconsole.conf
echo 'arch-vm' > /etc/hostname
printf '127.0.0.1 localhost\n::1       localhost\n127.0.1.1 arch-vm.localdomain arch-vm\n' > /etc/hosts

# Initramfs with LUKS: sd-encrypt added after block
sed -i -E 's/^HOOKS=.*/HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt filesystems fsck)/' /etc/mkinitcpio.conf
mkinitcpio -P

# Limine: an NVRAM entry, plus the removable path as a fallback if NVRAM is lost
mkdir -p /boot/EFI/limine /boot/EFI/BOOT
cp /usr/share/limine/BOOTX64.EFI /boot/EFI/limine/BOOTX64.EFI
cp /usr/share/limine/BOOTX64.EFI /boot/EFI/BOOT/BOOTX64.EFI
efibootmgr --create --disk /dev/vda --part 1 --label 'Arch Linux (Limine)' --loader '\EFI\limine\BOOTX64.EFI' --unicode
```

`/boot/limine.conf` (put your own value from `cryptsetup luksUUID /dev/vda2`). Limine finds it at the
ESP root from either EFI path:

```
timeout: 3

/Arch Linux
    protocol: linux
    path: boot():/vmlinuz-linux
    cmdline: rd.luks.name=<luks-uuid>=root root=/dev/mapper/root rootflags=subvol=@ rw
    module_path: boot():/initramfs-linux.img
```

`/etc/pacman.d/hooks/99-limine.hook`, which keeps both EFI binaries current:

```ini
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = limine

[Action]
Description = Updating the Limine EFI binaries
When = PostTransaction
Exec = /bin/sh -c 'cp /usr/share/limine/BOOTX64.EFI /boot/EFI/limine/BOOTX64.EFI && cp /usr/share/limine/BOOTX64.EFI /boot/EFI/BOOT/BOOTX64.EFI'
```

User, sudo and services:

```bash
useradd -m -G wheel -s /bin/bash user
echo '%wheel ALL=(ALL:ALL) ALL' > /etc/sudoers.d/10-wheel
chmod 440 /etc/sudoers.d/10-wheel
systemctl enable NetworkManager
passwd user
passwd root
```

### VM-only development access

Not part of the reproducible system. Skip all of this on real hardware.

```bash
install -d -m 700 -o user -g user /home/user/.ssh
install -m 600 -o user -g user /dev/null /home/user/.ssh/authorized_keys
cat ~/arch-vm_ed25519.pub > /home/user/.ssh/authorized_keys   # the host's VM-only public key
echo 'user ALL=(ALL:ALL) NOPASSWD: ALL' > /etc/sudoers.d/99-vm-dev
chmod 440 /etc/sudoers.d/99-vm-dev
printf 'PasswordAuthentication no\nPermitRootLogin no\n' > /etc/ssh/sshd_config.d/10-vm-dev.conf
systemctl enable sshd
```

## 5. First boot (host)

```bash
# In the live ISO:
sync; umount -R /mnt && cryptsetup close root; systemctl poweroff

# On the host, once it's off:
virsh -c qemu:///session detach-disk arch-vm sda --config   # both empty CD drives
virsh -c qemu:///session detach-disk arch-vm sdb --config
virsh -c qemu:///session start arch-vm
```

Unlock LUKS in the console (`virt-viewer --attach -c qemu:///session arch-vm`), or run `dev/vm-unlock.sh`, which
sends the passphrase as keystrokes.

`virsh screenshot` doesn't work while SPICE OpenGL is on (`screendump: no surface`). Use a viewer to see
the console.

## 6. Snapshot

Offline, so it's consistent and doesn't depend on UEFI snapshot support. The NVRAM isn't captured,
which is why Limine is also on the removable path.

```bash
virsh -c qemu:///session shutdown arch-vm
qemu-img snapshot -c 00-base ~/VMs/images/arch-vm.qcow2   # once it's off
qemu-img snapshot -l ~/VMs/images/arch-vm.qcow2           # list
qemu-img snapshot -a 00-base ~/VMs/images/arch-vm.qcow2   # restore
```

## Differences on real hardware

- Boot the ISO from USB and work on its console. Skip `virt-install`, cloud-init and the VM-only section.
- Disks are usually `/dev/nvme0n1` with partitions `p1` and `p2`; adjust every `/dev/vda` reference.
- Add `linux-firmware` and your CPU's `intel-ucode` or `amd-ucode` to `pacstrap`. The `microcode` hook
  picks it up. `install.sh` also adds these when it detects real hardware.
- Set your own hostname and username. `install.sh` doesn't depend on either.
- Wi-Fi during install: use `iwctl` on the live ISO.
- Dual-booting: never run `sgdisk --zap-all`. Create partitions
  in free space and reuse the existing ESP, checking first that it has room for the kernel and initramfs.

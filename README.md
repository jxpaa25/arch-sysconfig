# arch-sysconfig

A plain Arch Linux desktop, rebuilt from one script. Hyprland on Wayland under uwsm, a small Quickshell
bar and shell of its own, and two black and white themes.

It started as my [Omarchy](https://omarchy.org) setup, with everything I didn't use taken out. Nothing here
depends on Omarchy at runtime. The parts that came from it are listed in
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

## What you get

| | |
|---|---|
| Desktop | Hyprland, uwsm, Quickshell (bar, launcher, notifications, lock, idle, polkit, panels) |
| Terminal | Ghostty, zsh, starship, atuin, tmux, herdr |
| Editors | Helix (default), LazyVim |
| Browsers | Zen (default), Firefox, Chromium |
| Audio and network | PipeWire, WirePlumber, NetworkManager, systemd-resolved, ufw |
| Tools | btop, lazygit, lazydocker, superfile, cava, fastfetch, mise, uv, Docker |
| System | zram, snapper with bootable snapshots on btrfs + Limine, drivers picked by detected GPU and CPU |

The full lists are in [packages/](packages). Almost everything comes from the official repos, and
[packages/aur.txt](packages/aur.txt) lists the exceptions.

## Install

Start from a fresh Arch install with a normal user who can use `sudo`, and a working network.
[docs/step-0-install.md](docs/step-0-install.md) has the exact base install this was tested on: LUKS2,
btrfs and Limine. Other setups work too, and simply go without bootable snapshots.

```bash
sudo pacman -Syu --needed git
git clone https://github.com/jxpaa25/arch-sysconfig.git
cd arch-sysconfig
./install.sh
```

It asks for your password once and never reboots by itself. When it finishes, reboot and log in on tty1,
which starts the desktop. Then check the result from a terminal:

```bash
tests/verify.sh
```

Allow 25 to 70 minutes, depending on your connection. Most of that is downloads and AUR builds:
`limine-snapper-sync` alone pulls in a 330 MB JDK to build with, and removes it afterwards.

Keep the clone where it is, because your dotfiles are links into it.

To rerun, use `./install.sh` again: it only changes what isn't already in place. Dotfiles already in your
home folder get moved to `~/.local/state/arch-sysconfig/backup-*`, never overwritten. To rerun one part, use
`./install.sh --only <module>`, and `./install.sh --list` shows them.

## Using it

| Keys | |
|---|---|
| `SUPER + SPACE` | Main menu: search apps and every action |
| `SUPER + K` | List of keybindings |
| `SUPER + RETURN` | Terminal |
| `SUPER + SHIFT + RETURN` | Browser |
| `SUPER + W` | Close window |
| `SUPER + 1`-`0` | Switch workspace |
| `SUPER + ALT + T` | Change theme |
| `SUPER + ESCAPE` | Lock, suspend, restart, shut down |

- The full list and where each bind came from: [docs/keybinds.md](docs/keybinds.md).
- Themes: `theme-set vantablack` or `theme-set ultrawhite`. They live in [themes/](themes).
- Shell settings such as font size, clock formats and idle times: `~/.config/quickshell/Commons/Settings.qml`.
- Per-machine Hyprland settings go in `~/.config/hypr/hosts/<hostname>.lua`.
- Wallpapers are optional. Put images in `~/Pictures/Wallpapers` and pick one from the menu. None ship here.
- How the shell differs from Omarchy's, and known limits: [docs/porting.md](docs/porting.md).

## What has been tested

Tested end to end in a QEMU/KVM VM with a virtio GPU, using a real clean install each time.

Not tested yet, because a VM can't exercise it: NVIDIA drivers and hybrid graphics, dual monitors, Wi-Fi,
Bluetooth, brightness keys, battery and lid handling, and system tray icons. That code is written and
marked untested. Expect to fix some of it on first contact with real hardware.

## Layout

```
install.sh        entry point, runs install/ in order
install/          one module per stage
packages/         what gets installed, one list per purpose
stow/             dotfiles, linked into your home folder with GNU Stow
themes/           colours for every app
templates/        files apps rewrite at runtime, so they get a copy
system/           files installed under /etc
tests/verify.sh   checks a finished install
docs/             the base install, keybindings and porting notes
```

## Licence

MIT, see [LICENSE](LICENSE). Copied code keeps its own notice in
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

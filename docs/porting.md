# Porting notes

Decisions and differences to carry into Step 3, the port of the Omarchy-based config.

- No VPN: Mullvad was dropped from the package list, so the bar's `vpn` widget and the
  `vpn-status` script don't get ported.
- `xdph.conf` loses its `custom_picker_binary` line. `hyprland-preview-share-picker` isn't on
  the AUR, so screen sharing uses the stock picker.
- Hyprland in Arch's repos is 0.57.1, while the host's Omarchy mirror lags at 0.56.2. Check the
  ported Lua config against 0.57. The other versions that matter match the host or are close:
  ghostty 1.4.0, herdr 0.9.5 (host 0.9.1), quickshell 0.3.2 (host 0.3.2.r7, slightly newer).
- `hyprland-welcome` opens on first run under the generated config. The real config has to stop it.
- `chromium-flags.conf` drops the host's `--load-extension` line, which points at Omarchy files.
- The White theme is renamed Ultrawhite: `themes/ultrawhite`, `theme-set ultrawhite`.
- The Share menu is built around LocalSend, which isn't on the package list. Decide when porting menus.
- Brightness keys drive `brightnessctl` only. Omarchy also handled external monitors over DDC with
  `ddcutil`, and Apple displays. Your HDMI monitor's brightness keys won't work without adding that.
- `screenshot` is much simpler than Omarchy's `omasnap`: click a window or drag a region. There's no
  keyboard window selection or annotation.
- `.zshrc` carries a short alias set. Omarchy's shell functions (`tdl`, `hdl`, `compress`, `ga`, the `ssh`
  reconnect wrapper and others) aren't ported, since none appear in your shell history.
- Neovim's colours come from `aether.nvim`, which Omarchy's authors publish on GitHub (`omacom/aether.nvim`).
  It's an ordinary plugin taking a palette, with no dependency on Omarchy itself, and it's what makes
  both themes match your current look.
- The screensaver is a wandering clock drawn by the shell. Omarchy's terminal text effects need
  `terminaltexteffects`, which isn't in Arch's repos.
- Clipboard history uses `cliphist` instead of Omarchy's own capture script. `pass-menu` copies with
  `wl-copy --sensitive` so passwords stay out of it. A plain `pass -c` in a terminal doesn't mark its copy
  as sensitive, so a password copied that way does land in the history. Use the picker, or
  `cliphist wipe` afterwards.

## The shell, compared with Omarchy's

About 4,700 lines of QML against Omarchy's 48,000, because it hard-codes your layout instead of hosting
plugins. What that leaves out:

- The bar's layout lives in `Bar/Bar.qml`. There's no dragging widgets around, moving the bar to another edge,
  or glass and clear backgrounds.
- The tray has no pinning. Everything sits in the drawer behind the chevron. UNTESTED: nothing in the VM
  puts an icon in the tray.
- The world clock is a list of your cities, with no globe, search or daylight strip. Edit them in
  `Commons/Settings.qml`.
- The network panel has no DNS provider picker, Wi-Fi QR code or speed test. "Connection settings" opens
  `nmtui` for anything else. UNTESTED for Wi-Fi: the VM only has a wired device.
- The power panel shows the battery and power profile, without the system info section.
- The lock screen has no fingerprint support and no clock. Wrong passwords lock you out for 2 minutes after
  10 tries.
- The clipboard list shows images by their size, with no thumbnails. Emoji are a list, not a grid.
- The menu has no Install or Remove section, and no font picker.
- Notifications have no grouping, and don't focus the sending window when clicked unless the app asks.
- The share menu appears empty unless LocalSend is installed.
- Text shows as coloured fringes on VM screenshots. That's subpixel antialiasing in the VM's terminal fonts
  and needs checking on real hardware.

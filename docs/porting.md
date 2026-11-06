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

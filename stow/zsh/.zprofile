# Start the desktop when logging in on tty1. No display manager is involved.
if uwsm check may-start; then
  exec uwsm start hyprland.desktop
fi

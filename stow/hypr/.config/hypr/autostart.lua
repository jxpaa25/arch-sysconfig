hl.on("hyprland.start", function()
  -- Slow app launch fix: set systemd and D-Bus activation variables before anything starts.
  hl.exec_cmd("dbus-update-activation-environment --systemd --all")

  -- Start the herdr server inside the graphical session, so its panes inherit
  -- WAYLAND_DISPLAY. A first SSH login would otherwise start it without clipboard access.
  hl.exec_cmd(desk.launch("herdr server"))

  -- The bar, menus, notifications and lock screen. A service, so it restarts if it crashes.
  hl.exec_cmd("systemctl --user start desk-shell.service")

  -- Night light. Leaves the screen alone until the bar's toggle asks otherwise.
  hl.exec_cmd(desk.launch("hyprsunset"))
end)

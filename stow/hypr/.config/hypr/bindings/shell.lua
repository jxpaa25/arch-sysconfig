-- Everything that talks to the Quickshell shell, over its IPC. See `qs ipc show`.

local function ipc(target, call, ...)
  local parts = { "qs ipc call", target, call }
  for _, value in ipairs({ ... }) do
    parts[#parts + 1] = "'" .. tostring(value) .. "'"
  end
  return table.concat(parts, " ")
end

local function menu(id)
  return ipc("menu", "toggle", id)
end

-- Launcher and menus.
desk.bind("SUPER + SPACE", "Main menu", menu("root"))
desk.bind("SUPER + ESCAPE", "System menu", menu("system"))
desk.bind("XF86PowerOff", "Power menu", menu("system"), { locked = true })
desk.bind("SUPER + CTRL + O", "Toggle menu", menu("toggle"))
desk.bind("SUPER + CTRL + H", "Hardware menu", menu("hardware"))
desk.bind("SUPER + CTRL + C", "Capture menu", menu("capture"))
desk.bind("SUPER + CTRL + S", "Share menu", menu("share"))
desk.bind("SUPER + SHIFT + CTRL + SPACE", "Theme menu", menu("theme"))
desk.bind("SUPER + ALT + T", "Theme menu", menu("theme"))
desk.bind("SUPER + K", "Keybindings", "keybindings hyprland")
desk.bind("SUPER + ALT + K", "Tmux keybindings", "keybindings tmux")
desk.bind("SUPER + CTRL + K", "Herdr keybindings", "keybindings herdr")
desk.bind("SUPER + SHIFT + SLASH", "Passwords", "pass-menu")

-- Pickers.
desk.bind("SUPER + CTRL + V", "Clipboard", ipc("clipboard", "toggle"))
desk.bind("SUPER + CTRL + E", "Emoji", ipc("emoji", "toggle"))
desk.bind("SUPER + CTRL + SPACE", "Wallpaper", ipc("wallpaper", "toggle"))
desk.bind("SUPER + CTRL + W", "Wallpaper", ipc("wallpaper", "toggle"))
desk.bind("SUPER + ALT + W", "Wallpaper", ipc("wallpaper", "toggle"))

-- The bar.
desk.bind("SUPER + SHIFT + SPACE", "Toggle top bar", ipc("shell", "toggleBar"))
desk.bind("SUPER + CTRL + ALT + F", "Toggle full screen desktop", "desktop-fullscreen")

-- Panels.
desk.bind("SUPER + CTRL + A", "Audio", ipc("panels", "toggle", "audio"))
desk.bind("SUPER + CTRL + B", "Bluetooth", ipc("panels", "toggle", "bluetooth"))
desk.bind("SUPER + CTRL + N", "Network", ipc("panels", "toggle", "network"))
desk.bind("SUPER + CTRL + D", "Display", ipc("panels", "toggle", "monitor"))
desk.bind("SUPER + CTRL + P", "Power", ipc("panels", "toggle", "power"))
desk.bind("SUPER + CTRL + ALT + D", "Calendar", ipc("panels", "toggle", "clock"))
desk.bind("SUPER + CTRL + ALT + E", "World clock", ipc("panels", "toggle", "worldclock"))
for i = 1, 9 do
  desk.bind("SUPER + CTRL + " .. i, "Bar panel " .. i, ipc("panels", "toggleAt", i))
end

-- Notifications. xkbcommon names this key "comma"; upper-case COMMA doesn't match.
desk.bind("SUPER + comma", "Dismiss or act on the last notification", ipc("notifications", "dismissOrAct"))
desk.bind("SUPER + ALT + comma", "Dismiss the last notification", ipc("notifications", "dismissLast"))
desk.bind("SUPER + SHIFT + comma", "Dismiss all notifications", ipc("notifications", "dismissAll"))
desk.bind("SUPER + CTRL + comma", "Control notifications with the keyboard", ipc("notifications", "keyboard"))
desk.bind("SUPER + SHIFT + ALT + comma", "Notification history", ipc("notifications", "history"))
desk.bind("SUPER + CTRL + ALT + comma", "Silence notifications", ipc("notifications", "toggleSilence"))

-- Session.
desk.bind("SUPER + CTRL + L", "Lock", ipc("lock", "lock"))
desk.bind("SUPER + CTRL + I", "Toggle locking on idle", ipc("idle", "toggleStayAwake"))

-- Capture.
desk.bind("ALT + PRINT", "Screen recording", "screen-record")
desk.bind("SUPER + CTRL + PRINT", "Text from screenshot", "capture-text")

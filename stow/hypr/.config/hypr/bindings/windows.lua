-- Windows, monitors and groups. Workspaces are in slots.lua.

desk.bind("SUPER + W", "Close window", hl.dsp.window.close())
desk.bind("SUPER + Q", "Close window", hl.dsp.window.close())
desk.bind("CTRL + ALT + DELETE", "Close all windows", "window-close-all")
desk.bind("SUPER + J", "Toggle window split", hl.dsp.layout("togglesplit"))
desk.bind("SUPER + P", "Pseudo window", hl.dsp.window.pseudo())
desk.bind("SUPER + T", "Toggle window floating/tiling", hl.dsp.window.float({ action = "toggle" }))
desk.bind("SUPER + F", "Full screen", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
desk.bind("SUPER + CTRL + F", "Tiled full screen", "window-tiled-fullscreen")
desk.bind("SUPER + ALT + F", "Full width", hl.dsp.window.fullscreen({ mode = "maximized" }))
desk.bind("SUPER + O", "Pop window out (float and pin)", "window-pop")
desk.bind("SUPER + BACKSPACE", "Toggle transparency on a window", "window-transparency")

desk.bind("SUPER + LEFT", "Focus on left window", hl.dsp.focus({ direction = "l" }))
desk.bind("SUPER + RIGHT", "Focus on right window", hl.dsp.focus({ direction = "r" }))
desk.bind("SUPER + UP", "Focus on above window", hl.dsp.focus({ direction = "u" }))
desk.bind("SUPER + DOWN", "Focus on below window", hl.dsp.focus({ direction = "d" }))

desk.bind("SUPER + SHIFT + LEFT", "Swap window to the left", hl.dsp.window.swap({ direction = "l" }))
desk.bind("SUPER + SHIFT + RIGHT", "Swap window to the right", hl.dsp.window.swap({ direction = "r" }))
desk.bind("SUPER + SHIFT + UP", "Swap window up", hl.dsp.window.swap({ direction = "u" }))
desk.bind("SUPER + SHIFT + DOWN", "Swap window down", hl.dsp.window.swap({ direction = "d" }))

desk.bind("ALT + SHIFT + TAB", "Reveal active window on top", hl.dsp.window.alter_zorder({ mode = "bottom" }))
desk.bind("ALT + TAB", "Focus on next window", hl.dsp.window.cycle_next())
desk.bind("ALT + SHIFT + TAB", "Focus on previous window", hl.dsp.window.cycle_next({ next = false }))
desk.bind("ALT + TAB", "Reveal active window on top", hl.dsp.window.bring_to_top())

-- code:20 and code:21 are the MINUS and EQUAL keys, whichever layout is active.
local function resize(mods, step, label)
  desk.bind(mods .. "code:20", "Expand window left" .. label, hl.dsp.window.resize({ x = -step, y = 0, relative = true }))
  desk.bind(mods .. "code:21", "Shrink window left" .. label, hl.dsp.window.resize({ x = step, y = 0, relative = true }))
  desk.bind(mods .. "SHIFT + code:20", "Shrink window up" .. label, hl.dsp.window.resize({ x = 0, y = -step, relative = true }))
  desk.bind(mods .. "SHIFT + code:21", "Expand window down" .. label, hl.dsp.window.resize({ x = 0, y = step, relative = true }))
end
resize("SUPER + ", 100, "")
resize("SUPER + ALT + ", 25, " a little")
resize("SUPER + CTRL + ", 300, " a lot")

desk.bind("SUPER + mouse:272", "Move window", hl.dsp.window.drag(), { mouse = true })
desk.bind("SUPER + mouse:273", "Resize window", hl.dsp.window.resize(), { mouse = true })

-- Monitors. Moving whole workspaces is left out on purpose, to keep slots paired.
desk.bind("CTRL + ALT + TAB", "Focus on next monitor", hl.dsp.focus({ monitor = "+1" }))
desk.bind("CTRL + ALT + SHIFT + TAB", "Focus on previous monitor", hl.dsp.focus({ monitor = "-1" }))
for key, direction in pairs({ LEFT = "l", RIGHT = "r", UP = "u", DOWN = "d" }) do
  desk.bind("SUPER + SHIFT + CTRL + " .. key, "Move window to " .. key:lower() .. " monitor", hl.dsp.window.move({ monitor = direction }))
end
desk.bind("SUPER + SLASH", "Monitor scaling up", "monitor-scaling up")
desk.bind("SUPER + ALT + SLASH", "Monitor scaling down", "monitor-scaling down")
desk.bind("SUPER + CTRL + Delete", "Toggle laptop display", "monitor-internal toggle")
desk.bind("SUPER + CTRL + ALT + Delete", "Toggle laptop display mirroring", "monitor-internal mirror")
desk.bind("switch:on:Lid Switch", nil, "monitor-internal lid-closed", { locked = true })
desk.bind("switch:off:Lid Switch", nil, "monitor-internal on", { locked = true })

desk.bind("SUPER + CTRL + Z", "Zoom in", function()
  local zoom = hl.get_config("cursor.zoom_factor") or 1
  hl.config({ cursor = { zoom_factor = zoom + 1 } })
end)
desk.bind("SUPER + CTRL + ALT + Z", "Reset zoom", function()
  hl.config({ cursor = { zoom_factor = 1 } })
end)

-- Scratchpad.
desk.bind("SUPER + S", "Toggle scratchpad", hl.dsp.workspace.toggle_special("scratchpad"))
desk.bind("SUPER + ALT + S", "Move window to scratchpad", hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))

-- Groups.
desk.bind("SUPER + G", "Toggle window grouping", hl.dsp.group.toggle())
desk.bind("SUPER + ALT + G", "Move active window out of group", hl.dsp.window.move({ out_of_group = true }))
desk.bind("SUPER + ALT + LEFT", "Move window to group on left", hl.dsp.window.move({ into_group = "l" }))
desk.bind("SUPER + ALT + RIGHT", "Move window to group on right", hl.dsp.window.move({ into_group = "r" }))
desk.bind("SUPER + ALT + UP", "Move window to group on top", hl.dsp.window.move({ into_group = "u" }))
desk.bind("SUPER + ALT + DOWN", "Move window to group on bottom", hl.dsp.window.move({ into_group = "d" }))
desk.bind("SUPER + ALT + TAB", "Next window in group", hl.dsp.group.next())
desk.bind("SUPER + ALT + SHIFT + TAB", "Previous window in group", hl.dsp.group.prev())
desk.bind("SUPER + CTRL + LEFT", "Move grouped window focus left", hl.dsp.group.prev())
desk.bind("SUPER + CTRL + RIGHT", "Move grouped window focus right", hl.dsp.group.next())
desk.bind("SUPER + ALT + mouse_down", "Next window in group", hl.dsp.group.next())
desk.bind("SUPER + ALT + mouse_up", "Previous window in group", hl.dsp.group.prev())
for index = 1, 5 do
  desk.bind("SUPER + ALT + code:" .. tostring(index + 9), "Switch to group window " .. index, hl.dsp.group.active({ index = index }))
end

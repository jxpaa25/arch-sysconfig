-- See https://wiki.hypr.land/configuring/basics/window-rules/

desk.window(".*", { suppress_event = "maximize" })

-- Fix some dragging issues with XWayland.
desk.window({
  class = "^$",
  title = "^$",
  xwayland = true,
  float = true,
  fullscreen = false,
  pin = false,
}, { no_focus = true })

-- Terminals, including TUIs launched under their own app-id.
desk.window("(com\\.mitchellh\\.ghostty|org\\.desk\\..*)", { tag = "+terminal" })

-- Browsers.
desk.window("((google-)?[cC]hrom(e|ium))", { tag = "+chromium-based-browser" })
desk.window("([fF]irefox|zen)", { tag = "+firefox-based-browser" })
desk.window({ tag = "chromium-based-browser" }, { tile = true })
-- The "is sharing your screen" bar.
desk.window({ title = ".*is sharing.*" }, { workspace = "special silent" })

-- Windows that float by default.
desk.window("(org\\.desk\\.btop|org\\.desk\\.float|imv|mpv)", { tag = "+floating-window" })
desk.window("xdg-desktop-portal-gtk", { tag = "+floating-window" })
desk.window({ tag = "floating-window" }, { float = true, center = true, size = { 875, 600 } })

-- Picture-in-picture.
desk.window({ title = "(Picture.?in.?[Pp]icture)" }, { tag = "+pip" })
desk.window({ tag = "pip" }, {
  float = true,
  pin = true,
  size = { 600, 338 },
  keep_aspect_ratio = true,
  border_size = 0,
  move = { "(monitor_w-window_w-40)", "(monitor_h*0.04)" },
})

-- Popped-out windows (SUPER + O).
desk.window({ tag = "pop" }, { rounding = 8 })

-- Windows tagged to keep the screen on.
desk.window({ tag = "noidle" }, { idle_inhibit = "always" })

-- Screenshot region selection shouldn't animate.
hl.layer_rule({ match = { namespace = "selection" }, no_anim = true, animation = "none" })

-- Opt in to subtle transparency. SUPER + BACKSPACE opts other windows in.
desk.transparent_window({ tag = "terminal" })
desk.transparent_window({ tag = "transparent" })

-- A floating window moved to another monitor keeps its offset from the origin, so a
-- popped-out window could land off-center or off a smaller screen. A dispatcher move
-- fires this before the window lands, so the centering waits a loop.
hl.on("window.move_to_workspace", function(window, workspace)
  if not (window and workspace and window.monitor and workspace.monitor) then
    return
  end
  if window.monitor.id == workspace.monitor.id then
    return
  end
  for _, tag in ipairs(window.tags or {}) do
    if tag == "pop" then
      local target = "address:" .. window.address
      hl.timer(function()
        hl.dispatch(hl.dsp.window.center({ window = target }))
      end, { timeout = 1, type = "oneshot" })
      return
    end
  end
end)

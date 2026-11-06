-- SUPER + C and friends do the same thing everywhere, including in terminals.

local function send_shortcut_once(mods, key)
  return function()
    hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down" }))
    hl.timer(function()
      hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
    end, { timeout = 50, type = "oneshot" })
  end
end

local function active_window_is_terminal()
  local window = hl.get_active_window()
  if not window then
    return false
  end
  for _, tag in ipairs(window.tags or {}) do
    if tag:gsub("%*$", "") == "terminal" then
      return true
    end
  end
  return false
end

local function universal(default_mods, default_key, terminal_mods, terminal_key)
  return function()
    if active_window_is_terminal() then
      send_shortcut_once(terminal_mods, terminal_key)()
    else
      send_shortcut_once(default_mods, default_key)()
    end
  end
end

desk.bind("SUPER + A", "Select all", send_shortcut_once("CTRL", "A"))
desk.bind("SUPER + C", "Universal copy", universal("CTRL", "C", "CTRL SHIFT", "C"))
desk.bind("SUPER + V", "Universal paste", universal("CTRL", "V", "CTRL SHIFT", "V"))
desk.bind("SUPER + X", "Universal cut", send_shortcut_once("CTRL", "X"))

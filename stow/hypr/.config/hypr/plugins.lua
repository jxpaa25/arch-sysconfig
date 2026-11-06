-- Plugins built locally, not through hyprpm. A plugin only loads into the exact Hyprland
-- version it was built against, so run hyprexpo-rebuild after every Hyprland update.

local hyprexpo = desk.home .. "/.local/src/hyprexpo/hyprexpo.so"
if not desk.read_line(hyprexpo) then
  return
end

-- Declared on every config pass. Hyprland loads it after the first pass, then reloads the
-- config so that the options and functions below become available.
hl.plugin.load(hyprexpo)

local function plugin_loaded(name)
  local plugins = hl.get_loaded_plugins()
  if type(plugins) ~= "table" then
    return false
  end
  for _, plugin in pairs(plugins) do
    if type(plugin) == "table" and plugin.name == name then
      return true
    end
  end
  return false
end

if plugin_loaded("hyprexpo") then
  -- Ten fixed slots in a 5x2 grid. With grouped monitors, each shows its own range, and
  -- picking a slot on one brings the other along (see bindings/slots.lua).
  local method = "first 1"
  local names = {}
  for name in pairs(desk.slot_offsets) do
    table.insert(names, name)
  end
  table.sort(names, function(a, b)
    return desk.slot_offsets[a] < desk.slot_offsets[b]
  end)
  for i = #names, 1, -1 do
    method = names[i] .. " first " .. (desk.slot_offsets[names[i]] + 1) .. ", " .. method
  end

  hl.config({
    plugin = {
      hyprexpo = {
        columns = 5,
        rows = 2,
        dynamic_grid = 0,
        skip_empty = 0,
        workspace_method = method,
        gaps_in = 8,
        gaps_out = 24,
        tile_rounding = 4,

        bg_col = "rgb(000000)",
        border_width = 2,
        border_color = "rgb(1a1a1a)",
        border_color_current = "rgb(ffffff)",
        border_color_hover = "rgb(8d8d8d)",
        border_color_focus = "rgb(cecece)",
        drag_drop_proxy_color = "0x24ffffff",
        drag_drop_proxy_active_color = "0x3dffffff",
      },
    },
  })

  desk.bind("SUPER + E", "Workspace overview", function()
    hl.plugin.hyprexpo.expo("toggle all")
  end)
end

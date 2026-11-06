-- Settings changed at runtime by scripts, which keep them in ~/.local/state.

-- monitor-internal writes a generated rule here to turn the laptop panel off or mirror it.
for _, name in ipairs({ "internal-monitor-disable", "internal-monitor-mirror" }) do
  local path = desk.toggles_dir .. "/" .. name .. ".lua"
  if desk.read_line(path) then
    dofile(path)
  end
end

-- toggle-touchpad records the name of a disabled touchpad here.
local disabled_touchpad = desk.read_line(desk.toggles_dir .. "/touchpad-disabled-name")
if disabled_touchpad and disabled_touchpad ~= "" then
  hl.device({ name = disabled_touchpad, enabled = false })
end

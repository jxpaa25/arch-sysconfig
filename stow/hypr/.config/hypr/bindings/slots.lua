-- Workspace slots. With several monitors configured in desk.slot_offsets, slot N means
-- workspace N+offset on each monitor. Every slot switch moves all of them together and
-- keeps focus on the monitor you were on. With a monitor missing, or none configured,
-- everything falls back to plain workspaces.

local grouped_offsets = desk.slot_offsets
local former_slot = nil

local function grouped_active()
  if next(grouped_offsets) == nil then return false end
  for name in pairs(grouped_offsets) do
    if hl.get_monitor(name) == nil then return false end
  end
  return true
end

local function slot_of(workspace_id)
  if workspace_id == nil or workspace_id < 1 or workspace_id > 20 then return nil end
  return (workspace_id - 1) % 10 + 1
end

local function workspace_for(monitor_name, slot)
  return tostring(slot + (grouped_offsets[monitor_name] or 0))
end

local function current_slot()
  local workspace = hl.get_active_workspace()
  return workspace and slot_of(workspace.id)
end

-- Switch both monitors to a slot, leaving focus on the focused monitor.
local function focus_slot(slot)
  if not grouped_active() then
    hl.dispatch(hl.dsp.focus({ workspace = tostring(slot) }))
    return
  end

  local focused = hl.get_active_monitor().name
  local from = current_slot()
  local cursor = hl.get_cursor_pos()
  local warped = false

  for name in pairs(grouped_offsets) do
    if name ~= focused then
      local target = workspace_for(name, slot)
      if hl.get_workspace(target) ~= nil then
        -- Switches the other monitor without touching focus or the cursor.
        hl.get_monitor(name):set_workspace({ workspace = target })
      else
        -- set_workspace can't create a workspace, but focusing one does (the
        -- rules in monitors.lua put it on the right monitor). That moves focus
        -- and warps the cursor, so both are restored below.
        hl.dispatch(hl.dsp.focus({ workspace = target }))
        warped = true
      end
    end
  end

  if warped then hl.dispatch(hl.dsp.focus({ monitor = focused })) end
  hl.dispatch(hl.dsp.focus({ workspace = workspace_for(focused, slot) }))
  if warped and cursor ~= nil then hl.dispatch(hl.dsp.cursor.move({ x = cursor.x, y = cursor.y })) end

  if from ~= nil and from ~= slot then former_slot = from end
end

-- Move the active window to its own monitor's slot-N workspace. With follow,
-- both monitors switch to the slot and the moved window keeps focus.
local function move_window_to_slot(slot, follow)
  local window = hl.get_active_window()
  if window == nil then return end

  if not grouped_active() then
    hl.dispatch(hl.dsp.window.move({ workspace = tostring(slot), follow = follow }))
    return
  end

  local monitor = window.monitor and window.monitor.name
  hl.dispatch(hl.dsp.window.move({ workspace = workspace_for(monitor, slot), follow = false }))
  if follow then
    focus_slot(slot)
    hl.dispatch(hl.dsp.focus({ window = "address:" .. window.address }))
  end
end

-- Next/previous slot among open ones (either half exists), wrapping around.
local function step_slot(delta)
  if not grouped_active() then
    hl.dispatch(hl.dsp.focus({ workspace = delta > 0 and "e+1" or "e-1" }))
    return
  end

  local current = current_slot()
  if current == nil then return end

  local seen, slots = {}, {}
  for _, workspace in ipairs(hl.get_workspaces()) do
    local slot = slot_of(workspace.id)
    if slot ~= nil and not seen[slot] then
      seen[slot] = true
      table.insert(slots, slot)
    end
  end
  table.sort(slots)

  for i, slot in ipairs(slots) do
    if slot == current then
      local next_slot = slots[(i - 1 + delta) % #slots + 1]
      if next_slot ~= current then focus_slot(next_slot) end
      return
    end
  end
end

local function focus_former_slot()
  if not grouped_active() then
    hl.dispatch(hl.dsp.focus({ workspace = "previous" }))
  elseif former_slot ~= nil then
    focus_slot(former_slot)
  end
end

-- Used by the bar's workspace widget, so that clicks match SUPER + N.
grouped_workspaces = { focus_slot = focus_slot }

-- When something outside these bindings switches only one monitor (e.g.
-- picking a workspace in the hyprexpo overview), bring the other monitor to
-- the same slot without moving focus. Once both share a slot nothing changes,
-- so this settles instead of bouncing. Workspaces that don't exist yet are
-- skipped, since set_workspace can't create them.
hl.on("workspace.active", function(workspace)
  if workspace == nil or not grouped_active() then return end
  local slot = slot_of(workspace.id)
  local source = workspace.monitor and workspace.monitor.name
  if slot == nil or grouped_offsets[source] == nil then return end

  for name in pairs(grouped_offsets) do
    if name ~= source then
      local monitor = hl.get_monitor(name)
      local active = monitor.active_workspace
      local target = workspace_for(name, slot)
      if (active == nil or slot_of(active.id) ~= slot) and hl.get_workspace(target) ~= nil then
        monitor:set_workspace({ workspace = target })
      end
    end
  end
end)

for workspace = 1, 10 do
  local key = "code:" .. tostring(workspace + 9)


  desk.bind("SUPER + " .. key, "Switch both monitors to workspace slot " .. workspace, function()
    focus_slot(workspace)
  end)

  desk.bind("SUPER + SHIFT + " .. key, "Move window to workspace slot " .. workspace, function()
    move_window_to_slot(workspace, true)
  end)

  desk.bind("SUPER + SHIFT + ALT + " .. key, "Move window silently to workspace slot " .. workspace, function()
    move_window_to_slot(workspace, false)
  end)
end

desk.bind("SUPER + TAB", "Next workspace slot", function() step_slot(1) end)
desk.bind("SUPER + SHIFT + TAB", "Previous workspace slot", function() step_slot(-1) end)
desk.bind("SUPER + CTRL + TAB", "Former workspace slot", focus_former_slot)
desk.bind("SUPER + mouse_down", "Scroll workspace slots forward", function() step_slot(1) end)
desk.bind("SUPER + mouse_up", "Scroll workspace slots backward", function() step_slot(-1) end)

-- Three-finger touchpad swipe steps through workspace slots (both monitors
-- together), like SUPER+TAB. Swipe left for the next slot, right for previous.
hl.gesture({ fingers = 3, direction = "left", action = function() step_slot(1) end })
hl.gesture({ fingers = 3, direction = "right", action = function() step_slot(-1) end })

-- workspaces can't end up on the wrong monitor and break the pairing.

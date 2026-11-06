-- Entry point. See https://wiki.hypr.land/configuring/
-- Machine-specific settings live in hosts/<hostname>.lua.

local home = os.getenv("HOME")

-- Lua caches required modules, which would make a config reload see stale files.
for module in pairs(package.loaded) do
  if module:match("^hypr%.") or module:match("^theme%.") then
    package.loaded[module] = nil
  end
end

-- ~/.local/state holds the current theme, ~/.config the config itself.
package.path = home .. "/.local/state/?.lua;" .. home .. "/.config/?.lua;" .. package.path

require("hypr.helpers")
require("hypr.envs")
require("hypr.monitors")
require("hypr.input")
require("hypr.looknfeel")
require("hypr.windows")
require("hypr.bindings.windows")
require("hypr.bindings.slots")
require("hypr.bindings.apps")
require("hypr.bindings.media")
require("hypr.bindings.clipboard")
require("hypr.bindings.shell")
require("hypr.autostart")
require("hypr.plugins")
require("hypr.toggles")

-- Theme last, so its colours win.
desk.require_optional("theme.current.hyprland")

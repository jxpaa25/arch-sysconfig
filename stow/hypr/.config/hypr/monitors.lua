-- Any monitor without its own rule. List monitors with: hyprctl monitors all
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

-- Slots keep paired workspaces on several monitors together (see bindings/slots.lua).
-- Off by default. A host enables it by setting this, as hosts/god-hand.lua does.
desk.slot_offsets = {}

desk.require_optional("hypr.hosts." .. desk.hostname)

-- Laptop with an external monitor.

hl.env("GDK_SCALE", "2")

-- HDMI-A-1 on the left, eDP-1 (laptop panel) on the right.
hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@144.00", position = "0x0", scale = 1.25 })
hl.monitor({ output = "eDP-1", mode = "1920x1080@144.03", position = "1536x0", scale = 1.25 })

-- Slot N means eDP-1 workspace N together with HDMI-A-1 workspace N+10.
desk.slot_offsets = { ["eDP-1"] = 0, ["HDMI-A-1"] = 10 }

for i = 1, 10 do
  hl.workspace_rule({ workspace = tostring(i), monitor = "eDP-1", default = (i == 1) })
  hl.workspace_rule({ workspace = tostring(i + 10), monitor = "HDMI-A-1", default = (i == 1) })
end

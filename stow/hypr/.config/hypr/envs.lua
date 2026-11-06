-- Session environment.

-- Scripts run from binds need this, and only hl.env reaches them.
hl.env("PATH", desk.home .. "/.local/bin:" .. (os.getenv("PATH") or "/usr/local/bin:/usr/bin"))

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Prefer Wayland everywhere.
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "gtk3")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
hl.env("OZONE_PLATFORM", "wayland")
hl.env("XDG_SESSION_TYPE", "wayland")

-- Screen sharing needs these.
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

hl.env("XCOMPOSEFILE", desk.home .. "/.XCompose")

-- NVIDIA. UNTESTED until it runs on real hardware; the VM has no NVIDIA GPU.
-- Reads sysfs: lspci would wake a suspended GPU, and that can outlast Hyprland's
-- config reload budget. On a hybrid laptop the iGPU drives the display, and forcing
-- NVIDIA's VA-API and GLX globally would break video in Chromium-based browsers.
local function gpu_vendors()
  local vendors = {}
  local pipe = io.popen("for d in /sys/bus/pci/devices/*; do case $(cat $d/class) in 0x03*) cat $d/vendor;; esac; done")
  if pipe then
    for vendor in pipe:lines() do
      vendors[vendor] = true
    end
    pipe:close()
  end
  return vendors
end

local vendors = gpu_vendors()
if vendors["0x10de"] then
  hl.env("NVD_BACKEND", "direct")
  if not vendors["0x8086"] and not vendors["0x1002"] then
    hl.env("LIBVA_DRIVER_NAME", "nvidia")
    hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
  end
end

hl.config({
  xwayland = {
    force_zero_scaling = true,
  },

  ecosystem = {
    no_update_news = true,
    no_donation_nag = true,
  },
})

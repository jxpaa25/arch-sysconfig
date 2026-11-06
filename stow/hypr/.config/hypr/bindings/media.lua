-- Media keys work on the lock screen too.
local locked = { locked = true }
local held = { locked = true, repeating = true }

local sink = "@DEFAULT_AUDIO_SINK@"
desk.bind("XF86AudioRaiseVolume", "Volume up", "wpctl set-volume -l 1 " .. sink .. " 5%+", held)
desk.bind("XF86AudioLowerVolume", "Volume down", "wpctl set-volume " .. sink .. " 5%-", held)
desk.bind("XF86AudioMute", "Mute", "wpctl set-mute " .. sink .. " toggle", locked)
desk.bind("ALT + XF86AudioRaiseVolume", "Volume up precise", "wpctl set-volume -l 1 " .. sink .. " 1%+", held)
desk.bind("ALT + XF86AudioLowerVolume", "Volume down precise", "wpctl set-volume " .. sink .. " 1%-", held)
desk.bind("XF86AudioMicMute", "Mute microphone", "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle", locked)
desk.bind("SHIFT + XF86AudioMute", "Switch audio output", "audio-output-switch", locked)

desk.bind("XF86AudioNext", "Next track", "playerctl next", locked)
desk.bind("ALT + XF86AudioPlay", "Next track", "playerctl next", locked)
desk.bind("XF86AudioPrev", "Previous track", "playerctl previous", locked)
desk.bind("ALT + SHIFT + XF86AudioPlay", "Previous track", "playerctl previous", locked)
desk.bind("XF86AudioPlay", "Play", "playerctl play-pause", locked)
desk.bind("XF86AudioPause", "Pause", "playerctl play-pause", locked)
-- playerctld shift makes the next player the one these keys control.
desk.bind("SHIFT + XF86AudioPlay", "Switch media source", "playerctld shift", locked)
desk.bind("SHIFT + XF86AudioPause", "Switch media source", "playerctld shift", locked)

desk.bind("XF86MonBrightnessUp", "Brightness up", "brightnessctl set 5%+", held)
desk.bind("XF86MonBrightnessDown", "Brightness down", "brightnessctl set 5%-", held)
desk.bind("SHIFT + XF86MonBrightnessUp", "Brightness maximum", "brightnessctl set 100%", held)
desk.bind("SHIFT + XF86MonBrightnessDown", "Brightness minimum", "brightnessctl set 1%", held)
desk.bind("ALT + XF86MonBrightnessUp", "Brightness up precise", "brightnessctl set 1%+", held)
desk.bind("ALT + XF86MonBrightnessDown", "Brightness down precise", "brightnessctl set 1%-", held)

local keyboard = "brightnessctl --device='*kbd_backlight*' "
desk.bind("XF86KbdBrightnessUp", "Keyboard brightness up", keyboard .. "set 10%+", held)
desk.bind("XF86KbdBrightnessDown", "Keyboard brightness down", keyboard .. "set 10%-", held)
desk.bind("CTRL + XF86MonBrightnessUp", "Keyboard brightness up", keyboard .. "set 10%+", held)
desk.bind("CTRL + XF86MonBrightnessDown", "Keyboard brightness down", keyboard .. "set 10%-", held)
desk.bind("XF86KbdLightOnOff", "Keyboard backlight cycle", "keyboard-backlight-cycle", locked)

desk.bind("SUPER + CTRL + T", "Toggle touchpad", "toggle-touchpad", locked)
desk.bind("XF86TouchpadToggle", "Toggle touchpad", "toggle-touchpad", locked)
desk.bind("XF86TouchpadOn", "Enable touchpad", "toggle-touchpad on", locked)
desk.bind("XF86TouchpadOff", "Disable touchpad", "toggle-touchpad off", locked)

desk.bind("XF86Eject", "Eject media", "eject", locked)

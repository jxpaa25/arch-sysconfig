hl.config({
  input = {
    -- English, Serbian Latin, Serbian Cyrillic. Switch with Left Alt + Right Alt.
    kb_layout = "us,rs,rs",
    kb_variant = ",latin,",
    kb_options = "compose:caps,shift:both_capslock_cancel,grp:alts_toggle",

    follow_mouse = 1,
    sensitivity = 0,

    repeat_rate = 40,
    repeat_delay = 250,
    numlock_by_default = true,

    touchpad = {
      natural_scroll = true,
      clickfinger_behavior = true,
      scroll_factor = 0.4,
    },
  },

  misc = {
    key_press_enables_dpms = true,
    mouse_move_enables_dpms = true,
  },
})

-- Scroll at a usable speed in terminals, including TUIs with their own app-id.
desk.window("com.mitchellh.ghostty", { scroll_touchpad = 0.2 })
desk.window({ class = "org\\.desk\\..*" }, { scroll_touchpad = 0.2 })

-- Rounded corners, soft shadows, blur and thin borders.
hl.config({
  general = {
    gaps_in = 6,
    gaps_out = 12,
    border_size = 1,
  },

  decoration = {
    rounding = 12,
    rounding_power = 3,

    shadow = {
      enabled = true,
      range = 30,
      render_power = 3,
      offset = { 0, 8 },
      color = "rgba(00000045)",
      color_inactive = "rgba(00000025)",
    },

    blur = {
      enabled = true,
      size = 8,
      passes = 3,
      new_optimizations = true,
      vibrancy = 0.2,
      popups = true,
    },
  },
})

-- Frosted glass behind Omarchy's menus and pop-ups, and omacast's launcher,
-- like macOS menus and Spotlight. Omarchy's Glassy windows toggle does this
-- too, but also makes every window see-through. ignore_alpha keeps the faint
-- full-screen scrim behind a menu unblurred, so only the card is frosted.
hl.layer_rule({
  match = { namespace = "^(omarchy-menu|omarchy-notifications|omarchy-osd|omarchy-polkit|omarchy-reminders|omarchy-clipboard|omarchy-emojis|omarchy-keyboard-panel|omarchy-network-qr|omacast)$" },
  blur = true,
  ignore_alpha = 0.3,
})

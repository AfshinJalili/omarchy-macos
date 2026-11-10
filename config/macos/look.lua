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

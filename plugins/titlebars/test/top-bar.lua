-- Test bed for keeping titlebars below the top bar: every window floats, and
-- the classes pick how each one opens. PLUGIN is the .so to load.
hl.monitor({ output = "WAYLAND-1", mode = "preferred", position = "auto", scale = "1" })
hl.config({
  general = { gaps_out = 12, border_size = 1 },
  decoration = { rounding = 12, rounding_power = 3 },
  animations = { enabled = false },
  input = { follow_mouse = 0 },
  misc = { disable_hyprland_logo = true, disable_splash_rendering = true, disable_watchdog_warning = true },
})
hl.window_rule({ match = { class = ".*" }, float = true })
-- Taller than the monitor: Hyprland centres it with its top off screen.
hl.window_rule({ match = { class = "^tall$" }, size = { 600, 2000 } })
hl.window_rule({ match = { class = "^small$" }, size = { 500, 300 } })

hl.plugin.load(os.getenv("PLUGIN"))
if hl.plugin.hyprbars then
  dofile(os.getenv("STYLE"))
end

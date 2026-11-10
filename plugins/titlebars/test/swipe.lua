-- Test bed for maximizedDecorations.cpp: a fullscreen window on workspace 1, a
-- maximized one on workspace 2, and a workspace slide slow enough to
-- screenshot. Run with test/run-swipe.sh.
local root = os.getenv("HYPRBARS_ROOT")

hl.monitor({ output = "WAYLAND-1", mode = "preferred", position = "auto", scale = "1" })
hl.config({
  general = { gaps_out = 20, border_size = 1 },
  misc = { disable_hyprland_logo = true, disable_splash_rendering = true, disable_watchdog_warning = true, background_color = "rgb(3a4a6a)" },
})
hl.animation({ leaf = "workspaces", enabled = true, speed = 60, bezier = "linear", style = "slide" })
hl.window_rule({ match = { class = ".*" }, float = true })

hl.plugin.load(os.getenv("HYPRBARS_PLUGIN"))
if hl.plugin.hyprbars then
  dofile(root .. "/test/style.lua")
end

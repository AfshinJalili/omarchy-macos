-- Test bed for scrolling and clicking in Mission Control: three workspaces with a window
-- each. Run with test/run-input.sh.
hl.monitor({ output = "WAYLAND-1", mode = "preferred", position = "auto", scale = "1" })
hl.config({
  misc = { disable_hyprland_logo = true, disable_splash_rendering = true, disable_watchdog_warning = true },
})
hl.plugin.load(os.getenv("MISSION_CONTROL_PLUGIN"))

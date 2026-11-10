-- Test bed for a dialog over a maximized window: every window floats, as on an
-- Omarchy floating workspace. PLUGINS lists .so files to load, space-separated.
hl.monitor({ output = "WAYLAND-1", mode = os.getenv("MODE") or "preferred", position = "auto", scale = "1" })
hl.config({
  misc = { disable_hyprland_logo = true, disable_splash_rendering = true, disable_watchdog_warning = true },
  input = { follow_mouse = 0 },
})
hl.window_rule({ match = { class = ".*" }, float = true })
-- What Omarchy gives portal dialogs such as file pickers (default/hypr/apps/system.lua).
if os.getenv("OMARCHY_DIALOG_RULES") then
  hl.window_rule({ match = { title = "^Dialog$" }, center = true })
  hl.window_rule({ match = { title = "^Dialog$" }, size = { 875, 600 } })
end
for path in (os.getenv("PLUGINS") or ""):gmatch("%S+") do
  hl.plugin.load(path)
end
if hl.plugin.hyprbars and os.getenv("STYLE") then
  dofile(os.getenv("STYLE"))
end

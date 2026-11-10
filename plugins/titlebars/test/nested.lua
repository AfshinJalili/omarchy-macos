-- Test bed: a nested Hyprland that loads the plugin from ./build, floats every
-- window, and opens a focused and an unfocused terminal.
-- Run with test/run-nested.sh [scale].
local root = os.getenv("HYPRBARS_ROOT")
local scale = os.getenv("HYPRBARS_SCALE") or "1"

hl.monitor({ output = "WAYLAND-1", mode = "preferred", position = "auto", scale = scale })
hl.config({
  general = { gaps_out = 20, border_size = 1 },
  decoration = { rounding = 12, rounding_power = 3 },
  animations = { enabled = false },
  misc = { disable_hyprland_logo = true, disable_splash_rendering = true, disable_watchdog_warning = true, background_color = "rgb(3a4a6a)" },
})
-- HYPRBARS_LAYOUT=docs packs the windows for README screenshots at 2x.
local docs = os.getenv("HYPRBARS_LAYOUT") == "docs"
hl.window_rule({ match = { class = ".*" }, float = true, size = docs and "460 110" or "560 160" })
hl.window_rule({ match = { title = "Unfocused.*" }, move = docs and "40 30" or "40 60" })
hl.window_rule({ match = { title = "Focused.*" }, move = docs and "40 190" or "40 260" })

hl.plugin.load(root .. "/build/hyprbars-macos.so")
if hl.plugin.hyprbars then
  dofile(root .. "/test/style.lua")
end

hl.on("hyprland.start", function()
  hl.exec_cmd("foot --title 'Unfocused window' -e sleep 600")
  hl.exec_cmd("sleep 0.6; foot --title 'Focused window — Terminal' -e sleep 600")
end)

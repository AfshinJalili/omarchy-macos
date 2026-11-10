-- Swap test: starts on Omarchy's packaged plugin; the run script then creates
-- test/.swap and reloads, the way a live session moves to this one.
local root = os.getenv("HYPRBARS_ROOT")
local OMARCHY = "/usr/lib/omarchy-hyprland-titlebars/titlebars.so"
local MACOS = root .. "/build/omarchy-macos-titlebars.so"
hl.monitor({ output = "WAYLAND-1", mode = "preferred", position = "auto", scale = "1" })
hl.config({ animations = { enabled = false }, misc = { disable_hyprland_logo = true, disable_splash_rendering = true } })
hl.window_rule({ match = { class = ".*" }, float = true, size = "560 160", move = "40 60" })

local function macos_loaded()
  for _, plugin in ipairs(hl.get_loaded_plugins()) do
    if plugin.name == "hyprbars" and tostring(plugin.version):find("^macos%-") then
      return true
    end
  end
  return false
end

local f = io.open(root .. "/test/.swap", "r")
if f then
  f:close()
  -- As the README's Omarchy wrapper does: Omarchy's plugin stays requested
  -- until this one has loaded, so for one reload both are loaded at once.
  hl.plugin.load(MACOS)
  if not macos_loaded() then hl.plugin.load(OMARCHY) end
else
  hl.plugin.load(OMARCHY)
end
if hl.plugin.hyprbars then dofile(root .. "/test/style.lua") end
hl.on("hyprland.start", function() hl.exec_cmd("foot -e sleep 600") end)

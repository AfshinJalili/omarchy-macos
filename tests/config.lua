-- Test bed for the whole config: Omarchy's helpers and floating workspaces,
-- with hypr.macos loaded from CONFIG_TREE (a copy of ~/.config's layout) the
-- way ~/.config/hypr/hyprland.lua loads it, before the workspace modes.
local tree = os.getenv("CONFIG_TREE")

-- What Omarchy's bootstrap does on every reload: forget the config modules,
-- so the next pass runs them afresh.
for name in pairs(package.loaded) do
  if name == "hypr" or name:find("^hypr%.") or name:find("^default%.hypr") then
    package.loaded[name] = nil
  end
end
package.path = tree .. "/?.lua;" .. (os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/?.lua;" .. package.path

hl.monitor({ output = "WAYLAND-1", mode = "preferred", position = "auto", scale = "1" })
hl.config({ misc = { disable_hyprland_logo = true, disable_splash_rendering = true, disable_watchdog_warning = true } })

require("default.hypr.helpers")
require("hypr.macos")

local workspace_modes = require("default.hypr.workspace-modes")
o.workspace_mode({ default = "floating" })
workspace_modes.apply()

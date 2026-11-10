-- Mission Control: the omarchy-macos-mission-control plugin (plugins/mission-control),
-- a fork of gloview (https://github.com/fedsfarm/gloview). The trackpad swipes
-- live in hypr.macos.gestures.
local plugin = require("hypr.macos.plugin")

-- A session that started with gloview keeps it until the next login: the two
-- hook the same Hyprland function and cannot both load.
local gloview = plugin.loaded(function(loaded)
  return loaded.name == "GloView"
end)

if not gloview and not plugin.load(plugin.MISSION_CONTROL) then
  return
end
if not plugin.mission_control() then
  return
end

-- Ctrl + Up is macOS's Mission Control key. Looked up when the key fires, so a
-- plugin reload never leaves a stale function.
o.bind("CTRL + UP", "Mission Control", function()
  local mission_control = plugin.mission_control()
  if mission_control then
    mission_control.toggle()
  end
end)

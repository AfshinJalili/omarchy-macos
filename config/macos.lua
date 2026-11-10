-- macOS on Omarchy: https://github.com/AfshinJalili/omarchy-macos
--
-- Each feature is a module in ~/.config/hypr/macos/. Turn them on or off in
-- ~/.config/hypr/macos/settings.lua, then reload Hyprland (hyprctl reload).

local options = require("hypr.macos.options")

local modules = {
  "look",
  "motion",
  "cursor",
  "spotlight",
  "titlebars",
  "mission_control",
  "gestures",
}

for _, name in ipairs(modules) do
  if options[name] then
    require("hypr.macos." .. name)
  end
end

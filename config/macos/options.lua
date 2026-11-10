-- The settings in effect: defaults.lua, with the user's settings.lua on top.
-- Omarchy's bootstrap drops cached hypr.* modules on every reload, so a changed
-- setting applies then.
local function read(name)
  local ok, values = pcall(require, name)
  return ok and type(values) == "table" and values or {}
end

local options = read("hypr.macos.defaults")
for key, value in pairs(read("hypr.macos.settings")) do
  options[key] = value
end
return options

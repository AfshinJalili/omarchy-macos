-- Loads omarchy-macos's Hyprland plugins, which may be absent or built for
-- another Hyprland version, without breaking the rest of the config.
--
-- hl.plugin.load only declares a plugin: after each config pass Hyprland loads
-- the ones declared for the first time, unloads every one no longer declared,
-- and reloads the config if that changed anything. A plugin stays loaded only
-- while every pass declares it.
local M = {}

-- Where install.sh puts the plugins it builds.
M.LIB = os.getenv("HOME") .. "/.local/lib/omarchy-macos/"
M.TITLEBARS = M.LIB .. "omarchy-macos-titlebars.so"
M.MISSION_CONTROL = M.LIB .. "omarchy-macos-mission-control.so"

function M.installed(path)
  local file = io.open(path, "r")
  if file then
    file:close()
  end
  return file ~= nil
end

-- Returns true when the plugin at `path` is installed and declared.
function M.load(path)
  if not M.installed(path) then
    return false
  end
  local ok, err = pcall(hl.plugin.load, path)
  if not ok then
    print("macos: plugin not loaded: " .. path .. ": " .. tostring(err))
  end
  return ok
end

-- The loaded plugin `matches` accepts, if any.
function M.loaded(matches)
  for _, loaded in ipairs(hl.get_loaded_plugins and hl.get_loaded_plugins() or {}) do
    if matches(loaded) then
      return loaded
    end
  end
end

-- Mission Control's Lua functions, once its plugin is loaded.
function M.mission_control()
  return hl.plugin.mission_control
end

return M

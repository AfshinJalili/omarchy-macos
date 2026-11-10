-- Loads omarchy-macos's Hyprland plugins, which may be absent or built for
-- another Hyprland version, without breaking the rest of the config.
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

-- Returns true when the plugin at `path` is installed and loads.
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

-- Mission Control's Lua functions. Until the next login a session can still
-- run gloview, the plugin it was forked from, under its old name.
function M.mission_control()
  return hl.plugin.mission_control or hl.plugin.gloview
end

return M

-- The WhiteSur cursor, when it is installed. omarchy-macos doesn't install it.
local THEME = "WhiteSur-cursors"
local plugin = require("hypr.macos.plugin")

if plugin.installed(os.getenv("HOME") .. "/.local/share/icons/" .. THEME .. "/index.theme") then
  hl.env("XCURSOR_THEME", THEME)
end

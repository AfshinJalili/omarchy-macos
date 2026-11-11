-- macOS traffic-light titlebars on floating workspaces.
-- Omarchy loads its titlebar plugin from default/hypr/workspace-modes.lua after
-- this file, then adds close, maximize and minimize buttons. Two wrappers turn
-- those into macOS traffic lights on the left (close, minimize, zoom):
--   * hl.plugin.load swaps in omarchy-macos-titlebars (plugins/titlebars) when
--     it is installed and loads; otherwise Omarchy's own plugin stays.
--   * add_button replaces Omarchy's buttons with the three lights.
-- Stateless: the close button ("×") brings all three lights; Omarchy's own
-- maximize and minimize calls are dropped. Nothing is counted across calls,
-- because the plugin table can outlive a config reload.

local plugin = require("hypr.macos.plugin")
-- Full screen gives a zoomed window back zoomed, like the zoom light expects.
require("hypr.macos.zoom")

local TITLEBARS = "/usr/lib/omarchy-hyprland-titlebars/titlebars.so"
local MACOS_TITLEBARS = plugin.TITLEBARS
local WINDOW = [[window = "address:%WINDOW%"]]
local MINIMIZE = "omarchy-hyprland-window-minimize %WINDOW%"
local ZOOM = "hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = \"maximized\", action = \"toggle\", " .. WINDOW .. " })'"
local STOCK_ICONS = { ["×"] = true, ["□"] = true, ["−"] = true }

-- omarchy-macos-titlebars takes Omarchy's plugin name and reports a version
-- starting with "macos-".
local function macos_titlebars_loaded()
  return plugin.loaded(function(loaded)
    return loaded.name == "hyprbars" and tostring(loaded.version):find("^macos%-") ~= nil
  end) ~= nil
end

local function restyle(bars)
  if bars.__macos then
    return
  end
  local stock_add = bars.add_button

  bars.add_button = function(button)
    if not STOCK_ICONS[button.icon] then
      return stock_add(button)
    end
    if button.icon ~= "×" then
      return
    end
    -- omarchy-macos-titlebars draws each light and its glyph itself; Omarchy's plugin
    -- would draw the glyph names as text, so its lights stay blank.
    local drawn = macos_titlebars_loaded()
    local lights = {
      { color = "rgb(ff5f57)", glyph = "rgba(4d0000d9)", icon = "close", action = button.action },
      { color = "rgb(febc2e)", glyph = "rgba(985712d9)", icon = "minimize", action = MINIMIZE },
      { color = "rgb(28c840)", glyph = "rgba(0a5d17d9)", icon = "fullscreen", action = ZOOM },
    }
    local ok = pcall(function()
      hl.config({
        plugin = {
          hyprbars = {
            -- macOS proportions: a 28px bar, a 13px semibold title, 12px lights.
            bar_height = 28,
            bar_text_font = "Inter",
            bar_text_size = 13,
            bar_text_weight = "semibold",
            -- Unfocused windows show grey lights, as on macOS. Omarchy paints
            -- them in the bar colour, which makes them vanish. A translucent
            -- mid-grey reads right on both the light and dark bar.
            inactive_button_color = "rgba(80808066)",
            bar_text_align = "center",
            bar_buttons_alignment = "left",
            bar_padding = 12,
            bar_button_padding = 8,
            button_rounding = -1,
            icon_on_hover = true,
          },
        },
      })
      if drawn then
        -- Only omarchy-macos-titlebars knows this option.
        hl.config({ plugin = { hyprbars = { inactive_title_opacity = 50 } } })
      end
      for _, light in ipairs(lights) do
        stock_add({
          bg_color = light.color,
          fg_color = light.glyph,
          size = 12,
          icon = drawn and light.icon or "",
          action = light.action,
        })
      end
    end)
    if not ok then
      stock_add(button)
    end
  end
  bars.__macos = true
end

local stock_load = hl.plugin.load
hl.plugin.load = function(path, ...)
  local result
  if path == TITLEBARS and plugin.installed(MACOS_TITLEBARS) then
    -- A build made for another Hyprland version fails to load; Omarchy's
    -- plugin then takes its place, so floating windows keep their titlebars.
    local ok, loaded = pcall(stock_load, MACOS_TITLEBARS, ...)
    if ok and macos_titlebars_loaded() then
      result = loaded
    else
      result = stock_load(path, ...)
    end
  else
    result = stock_load(path, ...)
  end
  if path == TITLEBARS and hl.plugin.hyprbars then
    pcall(restyle, hl.plugin.hyprbars)
  end
  return result
end

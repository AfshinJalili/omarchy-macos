-- The settings and buttons the test bed applies; mirrors how a user would
-- configure the plugin.
local window = [[window = "address:%WINDOW%"]]
hl.config({ plugin = { hyprbars = {
  enabled = true,
  bar_height = 28,
  bar_text_font = "Inter",
  bar_text_size = 13,
  bar_text_weight = "semibold",
  bar_text_align = "center",
  bar_buttons_alignment = "left",
  bar_padding = 12,
  bar_button_padding = 8,
  button_rounding = -1,
  icon_on_hover = true,
  bar_color = "rgb(323232)",
  col = { text = "rgb(e6e6e6)" },
  inactive_button_color = "rgba(80808066)",
  inactive_title_opacity = 50,
} } })
for _, b in ipairs({
  { color = "rgb(ff5f57)", glyph = "rgba(4d0000d9)", icon = "close", action = "hyprctl dispatch 'hl.dsp.window.close({ " .. window .. " })'" },
  { color = "rgb(febc2e)", glyph = "rgba(985712d9)", icon = "minimize", action = "true" },
  { color = "rgb(28c840)", glyph = "rgba(0a5d17d9)", icon = "fullscreen", action = "true" },
}) do
  hl.plugin.hyprbars.add_button({ bg_color = b.color, fg_color = b.glyph, size = 12, icon = b.icon, action = b.action })
end

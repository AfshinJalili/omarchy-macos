#pragma once

// Traffic lights: draws a titlebar button as a macOS-style light, an
// anti-aliased circle with a faint rim and an optional vector glyph, into a
// texture at the exact pixel size it is shown at.

#include <string>
#include <hyprland/src/helpers/Color.hpp>
#include <hyprland/src/render/Texture.hpp>

enum class eLightGlyph {
  NONE,       // no recognised glyph: the button keeps its text icon
  CLOSE,      // ×
  MINIMIZE,   // −
  ZOOM,       // +
  FULLSCREEN, // two triangles pointing at opposite corners
};

// Maps a button's icon to the glyph drawn inside its light. Accepts the names
// ("close", "minimize", "zoom", "fullscreen") and the symbols Omarchy and
// hyprbars configs already use.
eLightGlyph lightGlyphFor(const std::string &icon);

// Renders one light diameterPx pixels wide. withGlyph draws the glyph in
// glyphColor; fill is the light's face colour.
SP<Render::ITexture> renderLight(int diameterPx, const CHyprColor &fill, eLightGlyph glyph, bool withGlyph, const CHyprColor &glyphColor);

#include "lights.hpp"

#include <algorithm>
#include <cairo/cairo.h>
#include <cmath>
#include <hyprland/src/render/Renderer.hpp>

eLightGlyph lightGlyphFor(const std::string &icon) {
  if (icon == "close" || icon == "×" || icon == "x" || icon == "✕")
    return eLightGlyph::CLOSE;
  if (icon == "minimize" || icon == "−" || icon == "-" || icon == "–")
    return eLightGlyph::MINIMIZE;
  if (icon == "zoom" || icon == "+")
    return eLightGlyph::ZOOM;
  if (icon == "fullscreen" || icon == "maximize" || icon == "□" || icon == "⤢")
    return eLightGlyph::FULLSCREEN;
  return eLightGlyph::NONE;
}

static void setSource(cairo_t *cr, const CHyprColor &c) { cairo_set_source_rgba(cr, c.r, c.g, c.b, c.a); }

static void drawGlyph(cairo_t *cr, eLightGlyph glyph, double c, double r, const CHyprColor &color) {
  setSource(cr, color);
  cairo_set_line_cap(cr, CAIRO_LINE_CAP_ROUND);
  // Strokes scale with the light so the glyph keeps macOS's weight at any size.
  cairo_set_line_width(cr, std::max(1.0, r * 0.16));

  // How far the glyph reaches from the centre, as a share of the radius.
  const double arm = r * 0.42;

  switch (glyph) {
    case eLightGlyph::CLOSE:
      cairo_move_to(cr, c - arm * 0.82, c - arm * 0.82);
      cairo_line_to(cr, c + arm * 0.82, c + arm * 0.82);
      cairo_move_to(cr, c + arm * 0.82, c - arm * 0.82);
      cairo_line_to(cr, c - arm * 0.82, c + arm * 0.82);
      cairo_stroke(cr);
      break;
    case eLightGlyph::MINIMIZE:
      cairo_move_to(cr, c - arm, c);
      cairo_line_to(cr, c + arm, c);
      cairo_stroke(cr);
      break;
    case eLightGlyph::ZOOM:
      cairo_move_to(cr, c - arm, c);
      cairo_line_to(cr, c + arm, c);
      cairo_move_to(cr, c, c - arm);
      cairo_line_to(cr, c, c + arm);
      cairo_stroke(cr);
      break;
    case eLightGlyph::FULLSCREEN: {
      // Two solid right triangles, their right angles in the top-left and
      // bottom-right corners, leaving a diagonal gap between them.
      const double a = arm * 0.9, b = arm * 0.2;
      cairo_move_to(cr, c - a, c - a);
      cairo_line_to(cr, c + b, c - a);
      cairo_line_to(cr, c - a, c + b);
      cairo_close_path(cr);
      cairo_move_to(cr, c + a, c + a);
      cairo_line_to(cr, c - b, c + a);
      cairo_line_to(cr, c + a, c - b);
      cairo_close_path(cr);
      cairo_fill(cr);
      break;
    }
    case eLightGlyph::NONE: break;
  }
}

SP<Render::ITexture> renderLight(int diameterPx, const CHyprColor &fill, eLightGlyph glyph, bool withGlyph, const CHyprColor &glyphColor) {
  const int size = std::max(2, diameterPx);
  auto *surface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, size, size);
  auto *cr = cairo_create(surface);
  cairo_set_antialias(cr, CAIRO_ANTIALIAS_BEST);

  const double c = size / 2.0;
  const double r = size / 2.0;

  // Face.
  cairo_arc(cr, c, c, r, 0, 2 * M_PI);
  setSource(cr, fill);
  cairo_fill(cr);

  // A faint darker rim just inside the edge, as macOS draws it, so the light
  // holds its shape against a bar of a similar tone.
  const double rim = std::max(0.6, size / 26.0);
  cairo_arc(cr, c, c, r - rim / 2.0, 0, 2 * M_PI);
  cairo_set_line_width(cr, rim);
  cairo_set_source_rgba(cr, 0, 0, 0, 0.14 * fill.a);
  cairo_stroke(cr);

  if (withGlyph)
    drawGlyph(cr, glyph, c, r, glyphColor);

  cairo_surface_flush(surface);
  auto tex = g_pHyprRenderer->createTexture(surface);
  cairo_destroy(cr);
  cairo_surface_destroy(surface);
  return tex;
}

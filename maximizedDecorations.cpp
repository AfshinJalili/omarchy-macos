#define WLR_USE_UNSTABLE

#include "maximizedDecorations.hpp"

#include <hyprland/src/debug/log/Logger.hpp>
#include <hyprland/src/managers/fullscreen/FullscreenController.hpp>
#include <hyprland/src/plugins/HookSystem.hpp>
#include <hyprland/src/render/Renderer.hpp>

#include <type_traits>

#include "globals.hpp"

// Works around a Hyprland bug. While a workspace with a fullscreen window is
// on screen, Hyprland draws the maximized windows of a workspace sliding past
// it with the decorate flag of the fullscreen workspace, not their own
// (Renderer.cpp, renderWorkspaceWindowsFullscreen). Their titlebars vanish for
// the length of the swipe.
//
// renderWindow is not part of the plugin API, so it is hooked by name. If
// Hyprland renames it the hook is skipped and only the swipe loses its bars.
// Delete this file once Hyprland passes the window's own state.

// renderWindow is protected; this only names it so its type can be read.
struct SRendererAccess : Render::IHyprRenderer {
  using IHyprRenderer::renderWindow;
};

// A hook takes the renderer first, then the arguments of the function it replaces.
template <typename... Args> auto hookType(void (Render::IHyprRenderer::*)(Args...)) -> void (*)(void *, Args...);
using RenderWindowHook = decltype(hookType(&SRendererAccess::renderWindow));

static CFunctionHook *g_renderWindowHook = nullptr;

static void hkRenderWindow(void *renderer, Render::CRenderContext &ctx, PHLWINDOW window, PHLMONITOR monitor, const Render::SWindowRenderPresentation &presentation,
                           const Time::steady_tp &time, bool decorate, Render::eRenderPassMode mode, bool ignorePosition, bool standalone) {
  // Standalone renders (screen sharing a window) are meant to be bare.
  if (!decorate && !standalone && Fullscreen::controller()->getFullscreenModes(window).internal == Fullscreen::FSMODE_MAXIMIZED)
    decorate = true;

  reinterpret_cast<RenderWindowHook>(g_renderWindowHook->m_original)(renderer, ctx, window, monitor, presentation, time, decorate, mode, ignorePosition, standalone);
}
static_assert(std::is_same_v<decltype(&hkRenderWindow), RenderWindowHook>, "IHyprRenderer::renderWindow changed: update hkRenderWindow to match");

void hookMaximizedDecorations() {
  void *address = nullptr;
  int matches = 0;
  for (const auto &match : HyprlandAPI::findFunctionsByName(OMARCHY_FLOATING_PHANDLE, "renderWindow")) {
    if (!match.demangled.contains("Renderer::renderWindow("))
      continue;
    address = match.address;
    matches++;
  }

  if (matches != 1) {
    Log::logger->log(Log::WARN, "hyprbars", "found {} renderWindow functions, expected 1: maximized windows lose their bar during a swipe", matches);
    return;
  }

  g_renderWindowHook = HyprlandAPI::createFunctionHook(OMARCHY_FLOATING_PHANDLE, address, reinterpret_cast<void *>(&hkRenderWindow));
  if (g_renderWindowHook && g_renderWindowHook->hook())
    return;

  Log::logger->log(Log::WARN, "hyprbars", "could not hook renderWindow: maximized windows lose their bar during a swipe");
  unhookMaximizedDecorations();
}

void unhookMaximizedDecorations() {
  if (!g_renderWindowHook)
    return;

  HyprlandAPI::removeFunctionHook(OMARCHY_FLOATING_PHANDLE, g_renderWindowHook);
  g_renderWindowHook = nullptr;
}

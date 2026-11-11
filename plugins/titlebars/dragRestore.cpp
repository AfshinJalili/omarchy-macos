#define WLR_USE_UNSTABLE

#include "dragRestore.hpp"

#include <hyprland/src/debug/log/Logger.hpp>
#include <hyprland/src/desktop/view/Window.hpp>
#include <hyprland/src/layout/target/WindowTarget.hpp>
#include <hyprland/src/plugins/HookSystem.hpp>

#include <type_traits>

#include "globals.hpp"

// A maximized window pulled down by its titlebar comes back to its own size
// under the pointer. Hyprland ends every animation of a dragged window on each
// pointer motion (CDragController::mouseMove calls warpPositionSize), so the
// window would drop to its small size in one frame. While that window is still
// shrinking, only its position is ended: it stays under the pointer, and its
// size animates down the way the zoom light restores it.
//
// warpPositionSize is not part of the plugin API, so it is hooked by name. If
// Hyprland renames it the hook is skipped and the window drops to size at once.

using WarpPositionSizeFn = void (*)(Layout::CWindowTarget *);

static CFunctionHook *g_warpHook = nullptr;
static PHLWINDOWREF g_restoring;

static bool shrinking(const PHLWINDOW &window) {
  return window && window->sizeAnimation() && window->sizeAnimation()->isBeingAnimated();
}

// Ends only the move, keeping the size animation going.
static void warpPosition(const PHLWINDOW &window) {
  window->positionAnimation()->warp();
  window->updateWindowDecos();
}

void animateDragRestore(PHLWINDOW window) {
  if (!window)
    return;

  if (!g_warpHook) {
    window->layoutTarget()->warpPositionSize();
    return;
  }

  g_restoring = window;
  warpPosition(window);
}

static void hkWarpPositionSize(Layout::CWindowTarget *target) {
  const auto restoring = g_restoring.lock();
  if (restoring && target && target->window() == restoring) {
    if (shrinking(restoring)) {
      warpPosition(restoring);
      return;
    }
    g_restoring.reset();
  }

  reinterpret_cast<WarpPositionSizeFn>(g_warpHook->m_original)(target);
}
static_assert(std::is_same_v<decltype(&Layout::CWindowTarget::warpPositionSize), void (Layout::CWindowTarget::*)()>,
              "CWindowTarget::warpPositionSize changed: update hkWarpPositionSize to match");

void hookDragRestore() {
  void *address = nullptr;
  int matches = 0;
  for (const auto &match : HyprlandAPI::findFunctionsByName(OMARCHY_FLOATING_PHANDLE, "warpPositionSize")) {
    if (!match.demangled.contains("CWindowTarget::warpPositionSize("))
      continue;
    address = match.address;
    matches++;
  }

  if (matches != 1) {
    Log::logger->log(Log::WARN, "[hyprbars] found {} CWindowTarget::warpPositionSize functions, expected 1: a maximized window dragged down drops to size at once", matches);
    return;
  }

  g_warpHook = HyprlandAPI::createFunctionHook(OMARCHY_FLOATING_PHANDLE, address, reinterpret_cast<void *>(&hkWarpPositionSize));
  if (g_warpHook && g_warpHook->hook())
    return;

  Log::logger->log(Log::WARN, "[hyprbars] could not hook CWindowTarget::warpPositionSize: a maximized window dragged down drops to size at once");
  unhookDragRestore();
}

void unhookDragRestore() {
  g_restoring.reset();

  if (!g_warpHook)
    return;

  HyprlandAPI::removeFunctionHook(OMARCHY_FLOATING_PHANDLE, g_warpHook);
  g_warpHook = nullptr;
}

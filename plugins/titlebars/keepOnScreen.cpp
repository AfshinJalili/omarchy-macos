#define WLR_USE_UNSTABLE

#include "keepOnScreen.hpp"

#include <hyprland/src/debug/log/Logger.hpp>
#include <hyprland/src/desktop/view/Window.hpp>
#include <hyprland/src/layout/LayoutManager.hpp>
#include <hyprland/src/layout/target/Target.hpp>
#include <hyprland/src/managers/eventLoop/EventLoopManager.hpp>
#include <hyprland/src/managers/fullscreen/FullscreenController.hpp>
#include <hyprland/src/managers/input/InputManager.hpp>
#include <hyprland/src/plugins/HookSystem.hpp>
#include <hyprland/src/state/MonitorState.hpp>

#include <algorithm>
#include <type_traits>

#include "barDeco.hpp"
#include "globals.hpp"

// The top bar is a layer above every window, so a titlebar that slides under
// it can no longer be grabbed. Hyprland lets that happen two ways: a drag
// carries a floating window anywhere, and a window too tall for the space
// under the top bar opens centred with its titlebar above that space. macOS
// keeps every titlebar below the menu bar; so does this.

static bool barShown(const PHLWINDOW &window) {
  return std::ranges::any_of(g_pOmarchyFloatingGlobalState->bars, [&window](const auto &bar) { return bar && bar->getOwner() == window && bar->shown(); });
}

// The highest the window's content may sit on `monitor`: the bar, and the
// border above it, start where the monitor's top bar ends.
static void clampToMonitor(const PHLWINDOW &window, const PHLMONITOR &monitor, eBarMove move) {
  if (!monitor || !window || !validMapped(window) || !window->m_isFloating || Fullscreen::controller()->isFullscreen(window) || !barShown(window))
    return;

  const auto target = window->layoutTarget();
  if (!target)
    return;

  // The bar's own extent can lag a frame behind it being shown.
  const double above = std::max<double>(window->getFullWindowReservedArea().topLeft.y, g_pOmarchyFloatingGlobalState->config.barHeight->value());
  const double top = monitor->logicalBoxMinusReserved().y + above;

  auto box = target->position();
  if (box.y >= top)
    return;

  box.y = top;
  g_layoutManager->setTargetGeom(box, target);
  if (move == eBarMove::JUMP)
    target->warpPositionSize();
}

void keepBarOnScreen(PHLWINDOW window, eBarMove move) {
  if (window)
    clampToMonitor(window, window->m_monitor.lock(), move);
}

// Windows waiting for the event loop to come round. The lock cancels the
// callback if the plugin unloads first.
static std::vector<std::pair<PHLWINDOWREF, eBarMove>> g_pending;
static UP<SEventLoopDoLaterLock> g_pendingLock;
static bool g_scheduled = false;

void keepBarOnScreenLater(PHLWINDOW window, eBarMove move) {
  if (!window)
    return;

  g_pending.emplace_back(window, move);
  if (g_scheduled)
    return;

  g_scheduled = true;
  g_pendingLock = g_pEventLoopManager->doLaterLock([] {
    g_scheduled = false;
    const auto windows = std::move(g_pending);
    g_pending.clear();
    for (const auto &[weak, move] : windows) {
      if (const auto window = weak.lock())
        keepBarOnScreen(window, move);
    }
  });
}

// A drag sets the window where the pointer puts it after the plugin hears of
// the motion, so the window is held back after Hyprland has moved it. The
// monitor under the pointer decides: a window crosses onto the monitor above
// once the pointer does, and stops at the top bar of the one it is on.
static CFunctionHook *g_moveMouseHook = nullptr;

using MoveMouseFn = void (*)(Layout::CLayoutManager *, const Vector2D &);

static void hkMoveMouse(Layout::CLayoutManager *manager, const Vector2D &mousePos) {
  reinterpret_cast<MoveMouseFn>(g_moveMouseHook->m_original)(manager, mousePos);

  const auto &drag = g_layoutManager->dragController();
  if (!drag || drag->mode() != MBIND_MOVE)
    return;

  const auto target = drag->target();
  if (!target)
    return;

  clampToMonitor(target->window(), State::monitorState()->query().vec(mousePos).run(), eBarMove::JUMP);
}
static_assert(std::is_same_v<decltype(&Layout::CLayoutManager::moveMouse), void (Layout::CLayoutManager::*)(const Vector2D &)>,
              "CLayoutManager::moveMouse changed: update hkMoveMouse to match");

void hookKeepOnScreen() {
  void *address = nullptr;
  int matches = 0;
  for (const auto &match : HyprlandAPI::findFunctionsByName(OMARCHY_FLOATING_PHANDLE, "moveMouse")) {
    if (!match.demangled.contains("CLayoutManager::moveMouse("))
      continue;
    address = match.address;
    matches++;
  }

  if (matches != 1) {
    Log::logger->log(Log::WARN, "hyprbars", "found {} CLayoutManager::moveMouse functions, expected 1: a drag can take a titlebar under the top bar", matches);
    return;
  }

  g_moveMouseHook = HyprlandAPI::createFunctionHook(OMARCHY_FLOATING_PHANDLE, address, reinterpret_cast<void *>(&hkMoveMouse));
  if (g_moveMouseHook && g_moveMouseHook->hook())
    return;

  Log::logger->log(Log::WARN, "hyprbars", "could not hook CLayoutManager::moveMouse: a drag can take a titlebar under the top bar");
  unhookKeepOnScreen();
}

void unhookKeepOnScreen() {
  g_pendingLock.reset();
  g_pending.clear();
  g_scheduled = false;

  if (!g_moveMouseHook)
    return;

  HyprlandAPI::removeFunctionHook(OMARCHY_FLOATING_PHANDLE, g_moveMouseHook);
  g_moveMouseHook = nullptr;
}

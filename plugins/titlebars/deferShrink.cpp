#define WLR_USE_UNSTABLE

#include "deferShrink.hpp"

#include <hyprland/src/debug/log/Logger.hpp>
#include <hyprland/src/desktop/view/Window.hpp>
#include <hyprland/src/managers/eventLoop/EventLoopManager.hpp>
#include <hyprland/src/managers/eventLoop/EventLoopTimer.hpp>
#include <hyprland/src/managers/fullscreen/FullscreenController.hpp>
#include <hyprland/src/plugins/HookSystem.hpp>
#include <hyprland/src/protocols/XDGShell.hpp>

#include <chrono>
#include <type_traits>

#include "globals.hpp"

// A floating window that shrinks with an animation, such as one coming back
// from maximized, is told its new size only once the animation ends.
//
// Hyprland tells the client the new size as the animation starts. A browser
// or an Electron app redraws at the small size at once, and Hyprland draws
// those buffers at their own size rather than the animated one, so the
// content snaps small while the window's box, blur and shadow shrink after it.
// Held at its old size, the client's last frame is scaled down with the box,
// the way a growing window's content grows with it.
//
// With plugin:hyprbars:live_resize on, a floating window whose size animates,
// growing or shrinking, is instead told each size along the way, as when its
// edge is dragged: whenever it has drawn the last size it was given, it gets
// the animated size of that moment, and the final size once the animation
// ends. Its content then lays out continuously with the box, at the cost of a
// full redraw for each step.
//
// sendWindowSize is not part of the plugin API, so it is hooked by name. If
// Hyprland renames it the hook is skipped and shrinking looks as before.

using SendWindowSizeFn = void (*)(Desktop::View::CWindow *, bool);

static CFunctionHook *g_sendWindowSizeHook = nullptr;
static std::vector<PHLWINDOWREF> g_held;
static std::vector<PHLWINDOWREF> g_live;
static SP<CEventLoopTimer> g_timer;

static constexpr auto POLL = std::chrono::milliseconds(16);
static constexpr auto STEP = std::chrono::milliseconds(4);

static void sendNow(const PHLWINDOW &window, bool force) {
  reinterpret_cast<SendWindowSizeFn>(g_sendWindowSizeHook->m_original)(window.get(), force);
}

static bool floatingAndAnimating(const PHLWINDOW &window) {
  if (!window || !window->m_isFloating || Fullscreen::controller()->isFullscreen(window))
    return false;

  const auto &size = window->sizeAnimation();
  return size && size->isBeingAnimated();
}

static bool shrinkingWithAnimation(const PHLWINDOW &window) {
  if (!floatingAndAnimating(window))
    return false;

  const auto &size = window->sizeAnimation();
  return size->goal().x < size->value().x - 1 || size->goal().y < size->value().y - 1;
}

static bool liveResize() {
  return g_pOmarchyFloatingGlobalState && g_pOmarchyFloatingGlobalState->config.liveResize && g_pOmarchyFloatingGlobalState->config.liveResize->value();
}

// An xdg client only: X11 clients are configured with a position too.
static bool resizesLive(const PHLWINDOW &window) {
  return liveResize() && floatingAndAnimating(window) && !window->m_isX11 && window->m_xdgSurface && window->m_xdgSurface->m_toplevel;
}

// The client has drawn the last size it was sent: it acked it and committed.
static bool caughtUp(const PHLWINDOW &window) {
  return window->m_pendingSizeAcks.empty() && !window->m_pendingSizeAck;
}

// Sends the animated size of this moment, as sendWindowSize sends the goal.
static void sendStep(const PHLWINDOW &window) {
  const auto size = window->sizeAnimation()->value().round().clamp(Vector2D{1, 1}, Math::VECTOR2D_MAX);
  if (size == window->m_pendingReportedSize)
    return;

  window->m_pendingReportedSize = size;
  window->m_pendingSizeAcks.emplace_back(window->m_xdgSurface->m_toplevel->setSize(size), size.floor());
}

// Sends each held window its size once its animation is over.
static void release(SP<CEventLoopTimer> self, void *) {
  std::erase_if(g_held, [](const PHLWINDOWREF &weak) {
    const auto window = weak.lock();
    if (!window)
      return true;
    if (window->sizeAnimation() && window->sizeAnimation()->isBeingAnimated())
      return false;
    sendNow(window, true);
    return true;
  });

  std::erase_if(g_live, [](const PHLWINDOWREF &weak) {
    const auto window = weak.lock();
    if (!window || !window->m_xdgSurface || !window->m_xdgSurface->m_toplevel)
      return true;
    if (!window->sizeAnimation() || !window->sizeAnimation()->isBeingAnimated()) {
      sendNow(window, true);
      return true;
    }
    if (caughtUp(window))
      sendStep(window);
    return false;
  });

  if (!g_live.empty())
    self->updateTimeout(STEP);
  else if (!g_held.empty())
    self->updateTimeout(POLL);
}

static void armTimer(std::chrono::milliseconds timeout) {
  if (!g_timer) {
    g_timer = makeShared<CEventLoopTimer>(timeout, release, nullptr);
    g_pEventLoopManager->addTimer(g_timer);
  } else if (!g_timer->armed() || timeout < POLL)
    g_timer->updateTimeout(timeout);
}

static void track(std::vector<PHLWINDOWREF> &list, const PHLWINDOW &window) {
  if (std::ranges::none_of(list, [&window](const PHLWINDOWREF &weak) { return weak.lock() == window; }))
    list.emplace_back(window);
}

static void hold(const PHLWINDOW &window) {
  track(g_held, window);
  armTimer(POLL);
}

static void resizeLive(const PHLWINDOW &window) {
  std::erase_if(g_held, [&window](const PHLWINDOWREF &weak) { return weak.lock() == window; });
  track(g_live, window);
  if (caughtUp(window))
    sendStep(window);
  armTimer(STEP);
}

static void hkSendWindowSize(Desktop::View::CWindow *self, bool force) {
  const auto window = self ? self->m_self.lock() : nullptr;
  if (window && resizesLive(window)) {
    resizeLive(window);
    return;
  }
  if (window && shrinkingWithAnimation(window)) {
    hold(window);
    return;
  }

  reinterpret_cast<SendWindowSizeFn>(g_sendWindowSizeHook->m_original)(self, force);
}
static_assert(std::is_same_v<decltype(&Desktop::View::CWindow::sendWindowSize), void (Desktop::View::CWindow::*)(bool)>,
              "CWindow::sendWindowSize changed: update hkSendWindowSize to match");

void hookDeferShrink() {
  void *address = nullptr;
  int matches = 0;
  for (const auto &match : HyprlandAPI::findFunctionsByName(OMARCHY_FLOATING_PHANDLE, "sendWindowSize")) {
    if (!match.demangled.contains("CWindow::sendWindowSize("))
      continue;
    address = match.address;
    matches++;
  }

  if (matches != 1) {
    Log::logger->log(Log::WARN, "[hyprbars] found {} CWindow::sendWindowSize functions, expected 1: a shrinking window's content snaps ahead of it", matches);
    return;
  }

  g_sendWindowSizeHook = HyprlandAPI::createFunctionHook(OMARCHY_FLOATING_PHANDLE, address, reinterpret_cast<void *>(&hkSendWindowSize));
  if (g_sendWindowSizeHook && g_sendWindowSizeHook->hook())
    return;

  Log::logger->log(Log::WARN, "[hyprbars] could not hook CWindow::sendWindowSize: a shrinking window's content snaps ahead of it");
  unhookDeferShrink();
}

void unhookDeferShrink() {
  // Windows still held get their size now, while the original is reachable.
  if (g_sendWindowSizeHook) {
    for (const auto &list : {g_held, g_live}) {
      for (const auto &weak : list) {
        if (const auto window = weak.lock())
          sendNow(window, true);
      }
    }
  }
  g_held.clear();
  g_live.clear();

  if (g_timer) {
    g_timer->cancel();
    g_pEventLoopManager->removeTimer(g_timer);
    g_timer.reset();
  }

  if (!g_sendWindowSizeHook)
    return;

  HyprlandAPI::removeFunctionHook(OMARCHY_FLOATING_PHANDLE, g_sendWindowSizeHook);
  g_sendWindowSizeHook = nullptr;
}

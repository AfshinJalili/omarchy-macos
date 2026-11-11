#define WLR_USE_UNSTABLE

#include "deferShrink.hpp"

#include <hyprland/src/debug/log/Logger.hpp>
#include <hyprland/src/desktop/view/window/Window.hpp>
#include <hyprland/src/desktop/view/window/WindowBackend.hpp>
#include <hyprland/src/layout/target/WindowTarget.hpp>
#include <hyprland/src/managers/eventLoop/EventLoopManager.hpp>
#include <hyprland/src/managers/eventLoop/EventLoopTimer.hpp>
#include <hyprland/src/managers/fullscreen/FullscreenController.hpp>
#include <hyprland/src/plugins/HookSystem.hpp>

#include <chrono>
#include <optional>
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
// Every size goes out through CWindowTarget::sendWindowSize (CWindow's only
// forwards to it). It is not part of the plugin API, so it is hooked by name.
// If Hyprland renames it the hook is skipped and shrinking looks as before.

using SendWindowSizeFn = void (*)(Layout::CWindowTarget *, bool);

struct SLiveWindow {
  PHLWINDOWREF window;
  std::optional<Vector2D> sent;
};

static CFunctionHook *g_sendWindowSizeHook = nullptr;
static std::vector<PHLWINDOWREF> g_held;
static std::vector<SLiveWindow> g_live;
static SP<CEventLoopTimer> g_timer;

static constexpr auto POLL = std::chrono::milliseconds(16);
static constexpr auto STEP = std::chrono::milliseconds(4);

// Only once the animation is over, so the hook lets it through.
static void sendFinal(const PHLWINDOW &window) {
  window->sendWindowSize(true);
}

static bool floatingAndAnimating(const PHLWINDOW &window) {
  if (!window || !window->isFloating() || Fullscreen::controller()->isFullscreen(window))
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

// A Wayland client only: X11 clients are configured with a position too.
static bool resizesLive(const PHLWINDOW &window) {
  return liveResize() && floatingAndAnimating(window) && window->backend().type() == Desktop::View::eBackendType::WINDOW_BACKEND_WAYLAND;
}

// The client has drawn the last size it was sent: it acked it and committed.
static bool caughtUp(const PHLWINDOW &window, const SLiveWindow &live) {
  return !live.sent || window->backend().reportedSize() == *live.sent;
}

// Sends the animated size of this moment, as sendWindowSize sends the goal.
static void sendStep(const PHLWINDOW &window, SLiveWindow &live) {
  const auto size = window->sizeAnimation()->value().round().clamp(Vector2D{1, 1}, Math::VECTOR2D_MAX);
  if (live.sent && size == *live.sent)
    return;

  window->backend().configure(CBox{window->position(Desktop::View::IGeometric::GEOMETRIC_GOAL), size}, window->m_monitor.lock());
  live.sent = size.floor();
}

// Sends each held window its size once its animation is over, and steps each
// live one.
static void release(SP<CEventLoopTimer> self, void *) {
  std::erase_if(g_held, [](const PHLWINDOWREF &weak) {
    const auto window = weak.lock();
    if (!window)
      return true;
    if (window->sizeAnimation() && window->sizeAnimation()->isBeingAnimated())
      return false;
    sendFinal(window);
    return true;
  });

  std::erase_if(g_live, [](SLiveWindow &live) {
    const auto window = live.window.lock();
    if (!window)
      return true;
    if (!window->sizeAnimation() || !window->sizeAnimation()->isBeingAnimated()) {
      sendFinal(window);
      return true;
    }
    if (caughtUp(window, live))
      sendStep(window, live);
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

static void hold(const PHLWINDOW &window) {
  if (std::ranges::none_of(g_held, [&window](const PHLWINDOWREF &weak) { return weak.lock() == window; }))
    g_held.emplace_back(window);
  armTimer(POLL);
}

static void resizeLive(const PHLWINDOW &window) {
  std::erase_if(g_held, [&window](const PHLWINDOWREF &weak) { return weak.lock() == window; });

  auto it = std::ranges::find_if(g_live, [&window](const SLiveWindow &live) { return live.window.lock() == window; });
  if (it == g_live.end()) {
    g_live.push_back({.window = window, .sent = std::nullopt});
    it = std::prev(g_live.end());
  }

  if (caughtUp(window, *it))
    sendStep(window, *it);
  armTimer(STEP);
}

static void hkSendWindowSize(Layout::CWindowTarget *target, bool force) {
  const auto window = target ? target->window() : nullptr;
  if (window && resizesLive(window)) {
    resizeLive(window);
    return;
  }
  if (window && shrinkingWithAnimation(window)) {
    hold(window);
    return;
  }

  reinterpret_cast<SendWindowSizeFn>(g_sendWindowSizeHook->m_original)(target, force);
}
static_assert(std::is_same_v<decltype(&Layout::CWindowTarget::sendWindowSize), void (Layout::CWindowTarget::*)(bool)>,
              "CWindowTarget::sendWindowSize changed: update hkSendWindowSize to match");

void hookDeferShrink() {
  void *address = nullptr;
  int matches = 0;
  for (const auto &match : HyprlandAPI::findFunctionsByName(OMARCHY_FLOATING_PHANDLE, "sendWindowSize")) {
    if (!match.demangled.contains("CWindowTarget::sendWindowSize("))
      continue;
    address = match.address;
    matches++;
  }

  if (matches != 1) {
    Log::logger->log(Log::WARN, "hyprbars", "found {} CWindowTarget::sendWindowSize functions, expected 1: a shrinking window's content snaps ahead of it", matches);
    return;
  }

  g_sendWindowSizeHook = HyprlandAPI::createFunctionHook(OMARCHY_FLOATING_PHANDLE, address, reinterpret_cast<void *>(&hkSendWindowSize));
  if (g_sendWindowSizeHook && g_sendWindowSizeHook->hook())
    return;

  Log::logger->log(Log::WARN, "hyprbars", "could not hook CWindowTarget::sendWindowSize: a shrinking window's content snaps ahead of it");
  unhookDeferShrink();
}

void unhookDeferShrink() {
  std::vector<PHLWINDOWREF> pending = std::move(g_held);
  for (const auto &live : g_live)
    pending.emplace_back(live.window);
  g_held.clear();
  g_live.clear();

  if (g_timer) {
    g_timer->cancel();
    g_pEventLoopManager->removeTimer(g_timer);
    g_timer.reset();
  }

  if (g_sendWindowSizeHook) {
    HyprlandAPI::removeFunctionHook(OMARCHY_FLOATING_PHANDLE, g_sendWindowSizeHook);
    g_sendWindowSizeHook = nullptr;
  }

  // Windows still held or stepping get their size now, with the hook gone.
  for (const auto &weak : pending) {
    if (const auto window = weak.lock())
      window->sendWindowSize(true);
  }
}

#pragma once

#include <hyprland/src/desktop/DesktopTypes.hpp>

// How a window held below the top bar gets there. A window coming back from
// maximized is already animating to its old place, so it slides on to the new
// one; jumping there would cut that animation short.
enum class eBarMove { JUMP, SLIDE };

// Keeps a floating window's titlebar below the top bar, so it can always be
// grabbed again.
void keepBarOnScreen(PHLWINDOW window, eBarMove move = eBarMove::JUMP);
// The same, once Hyprland has finished placing the window.
void keepBarOnScreenLater(PHLWINDOW window, eBarMove move = eBarMove::JUMP);

void hookKeepOnScreen();
void unhookKeepOnScreen();

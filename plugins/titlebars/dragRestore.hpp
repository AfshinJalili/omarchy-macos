#pragma once

#include <hyprland/src/desktop/DesktopTypes.hpp>

// Lets a maximized window pulled down by its titlebar shrink with an animation
// while it follows the pointer; see dragRestore.cpp.
void animateDragRestore(PHLWINDOW window);

void hookDragRestore();
void unhookDragRestore();

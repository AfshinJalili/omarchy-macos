#pragma once

// Keeps decorations on a maximized window that Hyprland draws without them
// while a fullscreen workspace is on screen; see maximizedDecorations.cpp.
void hookMaximizedDecorations();
void unhookMaximizedDecorations();

#pragma once

// Tells a floating window that shrinks with an animation its new size once the
// animation ends, so its content shrinks with it; see deferShrink.cpp.
void hookDeferShrink();
void unhookDeferShrink();

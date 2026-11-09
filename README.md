# omarchy-macos-gestures

macOS trackpad gestures for [Omarchy](https://omarchy.org), built on Hyprland's own
gestures, which follow your fingers. This is Lua config and one script. There is no
compiled plugin, so there is nothing to rebuild when Hyprland updates.

| Gesture | Does |
|---|---|
| 3 fingers left / right | Switch workspaces (Spaces) |
| 3 fingers up | Mission Control, via [gloview](https://github.com/fedsfarm/gloview). Swipe up again, press Esc or click to close |
| 3 fingers down | App Exposé: a picker with the focused app's windows |
| Pinch in, 4 fingers | Launchpad (Omarchy's app launcher) |
| Spread out, 4 fingers | Show Desktop: an empty workspace on this monitor. Spread again to come back |

Tap to click, two-finger right click and natural scrolling stay as Omarchy and your
`input.lua` set them.

**Three-finger drag:** set `THREE_FINGER_DRAG = true` at the top of `gestures.lua`.
As on macOS, the swipes then move to four fingers.

## Needs

- Omarchy on Hyprland 0.56 or later, with the Lua config.
- The macOS config layout: `~/.config/hypr/macos.lua` loading modules from
  `~/.config/hypr/macos/`.
- Optional: the gloview plugin, loaded by `hypr.macos.gloview`, for Mission Control.
  Without it the swipe up does nothing.
- `jq`, which Omarchy ships.

## Install

```sh
git clone https://github.com/AfshinJalili/omarchy-macos-gestures ~/Projects/omarchy-macos-gestures
~/Projects/omarchy-macos-gestures/install.sh
```

The installer links `gestures.lua` to `~/.config/hypr/macos/gestures.lua` and
`bin/omarchy-macos-app-expose` to `~/.local/bin/`. It then adds
`require("hypr.macos.gestures")` to `macos.lua` and reloads Hyprland. Edits in the
repo take effect on the next `hyprctl reload`.

`./uninstall.sh` undoes all of it.

## Not possible on Linux

Notification Center (a swipe from the right edge), Force Touch / Look Up and
smart zoom need Apple's trackpad hardware or drivers. Linux touchpads don't report
edge swipes or pressure.

# Working on omarchy-macos

macOS features for Omarchy: Lua config in `config/`, two Hyprland plugins in `plugins/`. Read `README.md` first.

## Never disturb the user's session

The user works in the Hyprland session you would test in.

- Test plugins and config only in a nested Hyprland started with `tools/nested.sh` (`nested_start`). It opens the session silently on an empty workspace (9), keeps it rendering there, and stops it on exit. Never start `Hyprland` yourself, never open test windows on the user's workspace, and never move their focus.
- Never load, unload or hot-reload a plugin into the user's session (`hyprctl plugin load/unload`, the CMake `reload` target). A plugin crash ends their session.
- Check `hyprctl activewindow` before and after a test run; it must not change.

## Branches

- `main` targets the newest Hyprland (0.57). The config, scripts and tests live here, and the user's checkout stays on `main`.
- `hyprland-0.56` carries the plugin sources for Hyprland 0.56. Only its `plugins/` is built (`hyprpm.toml` on `main` pins 0.56.x to a commit there).
- A plugin fix goes on both branches. After committing to `hyprland-0.56`, point the pins in `main`'s `hyprpm.toml` at the new commit.
- To compile `main` against 0.57 on a machine running 0.56, build 0.57 headers with `ci/hyprland-headers.sh v0.57.1 <prefix>` and set `PKG_CONFIG_PATH`.

## Tests

- `tests/run-config.sh`: the whole config with Omarchy's floating workspaces, and settings switched off.
- `tests/run-dialog.sh`: dialogs over a maximized window take clicks.
- `plugins/mission-control/test/run-input.sh`: scrolling and clicking in Mission Control.
- `plugins/titlebars/test/run-*.sh`: titlebar rendering, the swap with Omarchy's plugin, and the swipe.

Trackpad swipes can't be faked without root (uinput), so they are tested by hand.

## Hyprland facts that bit us

- `hl.plugin.load` only declares a plugin. After each config pass Hyprland loads new ones, unloads any no longer declared and reloads if that changed anything. Declare every wanted plugin on every pass, or it is unloaded, and a loop of reloads can follow.
- Omarchy's bootstrap clears cached `hypr.*` modules on each reload; the Lua state itself persists.
- `hyprctl repl` answers did not match what config code saw; check behaviour in a nested session instead.
- Hyprland's virtual pointer resets the axis source on every axis value, so `tools/pointer.c` sends the source after the value.

## Upstream

Mission Control is a hard fork of gloview and does not follow it. To take something from upstream, read its change at https://github.com/fedsfarm/gloview and port it by hand under the `mission_control` names.

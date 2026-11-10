#!/bin/bash
# Moves a titled window from a 1x monitor to a 2x one in a nested Hyprland and
# screenshots its titlebar on each, to check the title keeps its size.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/../../tools/nested.sh"
NESTED_LOG="$ROOT/test/nested.log" nested_start "$ROOT/test/nested.lua" HYPRBARS_ROOT="$ROOT" HYPRBARS_SCALE=1
sig="$NESTED_SIG" socket="$NESTED_SOCKET" pid="$NESTED_PID"
hyprctl output create wayland >/dev/null; sleep 2
second=$(hyprctl monitors -j | jq -r '.[] | select(.name != "WAYLAND-1") | .name' | head -1)
hyprctl eval "hl.monitor({ output = \"$second\", mode = \"preferred\", position = \"auto-right\", scale = \"2\" })" >/dev/null; sleep 1
hyprctl monitors -j | jq -c '.[] | {name, scale, x, y}'
win=$(hyprctl clients -j | jq -r '.[] | select(.title | startswith("Focused")) | .address')
WAYLAND_DISPLAY="$socket" grim -o WAYLAND-1 "$ROOT/test/mon1.png"
hyprctl eval "hl.dispatch(hl.dsp.window.move({ monitor = \"$second\", window = \"address:$win\" }))" >/dev/null; sleep 1
hyprctl clients -j | jq -c '.[] | {title, monitor, at}'
WAYLAND_DISPLAY="$socket" grim -o "$second" "$ROOT/test/mon2.png"

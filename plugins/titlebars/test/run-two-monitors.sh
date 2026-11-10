#!/bin/bash
# Moves a titled window from a 1x monitor to a 2x one in a nested Hyprland and
# screenshots its titlebar on each, to check the title keeps its size.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
before=$(ls "$XDG_RUNTIME_DIR"/hypr | sort)
sockets_before=$(cd "$XDG_RUNTIME_DIR" && ls -d wayland-* 2>/dev/null | grep -v lock | sort)
HYPRBARS_ROOT="$ROOT" HYPRBARS_SCALE=1 Hyprland -c "$ROOT/test/nested.lua" >"$ROOT/test/nested.log" 2>&1 &
pid=$!
trap 'kill $pid 2>/dev/null || true' EXIT
sleep 4
sig=$(comm -13 <(echo "$before") <(ls "$XDG_RUNTIME_DIR"/hypr | sort) | head -1)
socket=$(comm -13 <(echo "$sockets_before") <(cd "$XDG_RUNTIME_DIR" && ls -d wayland-* | grep -v lock | sort) | head -1)
[[ -n $socket && $socket != "$WAYLAND_DISPLAY" ]] || { echo "nested socket not found" >&2; exit 1; }
export HYPRLAND_INSTANCE_SIGNATURE="$sig"
hyprctl output create wayland >/dev/null; sleep 2
second=$(hyprctl monitors -j | jq -r '.[] | select(.name != "WAYLAND-1") | .name' | head -1)
hyprctl eval "hl.monitor({ output = \"$second\", mode = \"preferred\", position = \"auto-right\", scale = \"2\" })" >/dev/null; sleep 1
hyprctl monitors -j | jq -c '.[] | {name, scale, x, y}'
win=$(hyprctl clients -j | jq -r '.[] | select(.title | startswith("Focused")) | .address')
WAYLAND_DISPLAY="$socket" grim -o WAYLAND-1 "$ROOT/test/mon1.png"
hyprctl eval "hl.dispatch(hl.dsp.window.move({ monitor = \"$second\", window = \"address:$win\" }))" >/dev/null; sleep 1
hyprctl clients -j | jq -c '.[] | {title, monitor, at}'
WAYLAND_DISPLAY="$socket" grim -o "$second" "$ROOT/test/mon2.png"

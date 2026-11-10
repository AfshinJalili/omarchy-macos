#!/bin/bash
# Screenshot a maximized window sliding past a fullscreen workspace, which is
# when Hyprland drops its titlebar. Usage: test/run-swipe.sh [out.png] [plugin.so]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:-$ROOT/test/swipe.png}"
before=$(ls "$XDG_RUNTIME_DIR"/hypr 2>/dev/null | sort)
sockets_before=$(cd "$XDG_RUNTIME_DIR" && ls -d wayland-* 2>/dev/null | grep -v lock | sort)
HYPRBARS_ROOT="$ROOT" HYPRBARS_PLUGIN="${2:-$ROOT/build/omarchy-macos-titlebars.so}" Hyprland -c "$ROOT/test/swipe.lua" >"$ROOT/test/swipe.log" 2>&1 &
pid=$!
trap 'kill $pid 2>/dev/null || true' EXIT
sleep 4
sig=$(comm -13 <(echo "$before") <(ls "$XDG_RUNTIME_DIR"/hypr | sort) | head -1)
socket=$(comm -13 <(echo "$sockets_before") <(cd "$XDG_RUNTIME_DIR" && ls -d wayland-* | grep -v lock | sort) | head -1)
# Never fall back to the host display: a wrong socket would capture the real desktop.
[[ -n $socket && $socket != "$WAYLAND_DISPLAY" ]] || { echo "nested socket not found" >&2; exit 1; }
export HYPRLAND_INSTANCE_SIGNATURE="$sig"
run() { hyprctl eval "hl.dispatch($1)" >/dev/null; sleep "${2:-1}"; }

run 'hl.dsp.exec_cmd("foot --title Fullscreen -e sleep 600")' 1.5
run 'hl.dsp.window.fullscreen({ mode = "fullscreen" })'
run 'hl.dsp.focus({ workspace = "2" })' 7
run 'hl.dsp.exec_cmd("foot --title Maximized -e sleep 600")' 1.5
run 'hl.dsp.window.fullscreen({ mode = "maximized" })'
hyprctl configerrors
hyprctl plugin list -j | jq -c '[.[] | .version]'
hyprctl clients -j | jq -c '.[] | {title, workspace: .workspace.id, fullscreen}'
grep -h "\[hyprbars\]" "$ROOT/test/swipe.log" | grep -v Dragging || true

# Leave the maximized window: workspace 1 is active, and it slides out.
run 'hl.dsp.focus({ workspace = "1" })' 1.5
WAYLAND_DISPLAY="$socket" grim "$OUT"
kill -0 $pid && echo "alive, saved $OUT" || echo CRASHED

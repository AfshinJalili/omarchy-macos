#!/bin/bash
# Screenshot a maximized window sliding past a fullscreen workspace, which is
# when Hyprland drops its titlebar. Usage: test/run-swipe.sh [out.png] [plugin.so]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:-$ROOT/test/swipe.png}"
source "$ROOT/../../tools/nested.sh"
NESTED_LOG="$ROOT/test/swipe.log" nested_start "$ROOT/test/swipe.lua" HYPRBARS_ROOT="$ROOT" HYPRBARS_PLUGIN="${2:-$ROOT/build/omarchy-macos-titlebars.so}"
sig="$NESTED_SIG" socket="$NESTED_SOCKET" pid="$NESTED_PID"
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

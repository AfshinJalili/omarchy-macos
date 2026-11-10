#!/bin/bash
# Start a nested Hyprland with the test bed, screenshot it from inside, and
# stop it. Usage: test/run-nested.sh [scale] [out.png] [hover x,y]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCALE="${1:-1}"
OUT="${2:-$ROOT/test/shot-$SCALE.png}"
source "$ROOT/../../tools/nested.sh"
NESTED_LOG="$ROOT/test/nested.log" nested_start "$ROOT/test/nested.lua" HYPRBARS_ROOT="$ROOT" HYPRBARS_SCALE="$SCALE" HYPRBARS_LAYOUT="${HYPRBARS_LAYOUT:-}"
sig="$NESTED_SIG" socket="$NESTED_SOCKET" pid="$NESTED_PID"
echo "instance=$sig socket=$socket"
HYPRLAND_INSTANCE_SIGNATURE="$sig" hyprctl configerrors || true
HYPRLAND_INSTANCE_SIGNATURE="$sig" hyprctl clients -j | jq -c '.[] | {title, at, size}' || true
HYPRLAND_INSTANCE_SIGNATURE="$sig" hyprctl monitors -j | jq -c '.[] | {name, scale, width, height}'
if [[ -n ${3:-} ]]; then
  # Approach in steps: the bar tracks hover from pointer motion.
  for dx in 30 15 0; do
    HYPRLAND_INSTANCE_SIGNATURE="$sig" hyprctl eval "hl.dispatch(hl.dsp.cursor.move({ x = $(( ${3%,*} + dx )), y = ${3#*,} }))" >/dev/null
    sleep 0.3
  done
  sleep 0.5
fi
WAYLAND_DISPLAY="$socket" grim "$OUT"
echo "saved $OUT"

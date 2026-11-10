#!/bin/bash
# Start a nested Hyprland with the test bed, screenshot it from inside, and
# stop it. Usage: test/run-nested.sh [scale] [out.png] [hover x,y]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCALE="${1:-1}"
OUT="${2:-$ROOT/test/shot-$SCALE.png}"
before=$(ls "$XDG_RUNTIME_DIR"/hypr 2>/dev/null | sort)
sockets_before=$(cd "$XDG_RUNTIME_DIR" && ls -d wayland-* 2>/dev/null | grep -v lock | sort)
HYPRBARS_ROOT="$ROOT" HYPRBARS_SCALE="$SCALE" HYPRBARS_LAYOUT="${HYPRBARS_LAYOUT:-}" Hyprland -c "$ROOT/test/nested.lua" >"$ROOT/test/nested.log" 2>&1 &
pid=$!
trap 'kill $pid 2>/dev/null || true' EXIT
sleep 4
sig=$(comm -13 <(echo "$before") <(ls "$XDG_RUNTIME_DIR"/hypr | sort) | head -1)
socket=$(comm -13 <(echo "$sockets_before") <(cd "$XDG_RUNTIME_DIR" && ls -d wayland-* | grep -v lock | sort) | head -1)
# Never fall back to the host display: a wrong socket would capture the real desktop.
[[ -n $socket && $socket != "$WAYLAND_DISPLAY" ]] || { echo "nested socket not found" >&2; exit 1; }
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

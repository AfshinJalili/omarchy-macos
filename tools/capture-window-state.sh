#!/bin/bash
# Record what Hyprland does with windows while you reproduce a bug, for a
# minute or the number of seconds given: the window list every second and
# Hyprland's detailed log, which is switched on for the recording and off again
# afterwards. Everything is saved to ~/.cache/omarchy-macos/captures/<time>/,
# and nothing leaves the machine.
#
# Usage: tools/capture-window-state.sh [seconds]
set -euo pipefail

SECONDS_TO_RECORD="${1:-60}"
OUT="$HOME/.cache/omarchy-macos/captures/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUT"
LOG="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/hyprland.log"

restore() {
  hyprctl eval 'hl.config({ debug = { disable_logs = true } })' >/dev/null 2>&1 || true
}
trap restore EXIT

start_line=$(wc -l <"$LOG")
hyprctl eval 'hl.config({ debug = { disable_logs = false } })' >/dev/null

echo "Recording for $SECONDS_TO_RECORD seconds. Reproduce the bug now."
for ((i = 0; i < SECONDS_TO_RECORD; i++)); do
  {
    echo "=== $(date +%T)"
    echo "active: $(hyprctl activewindow -j | jq -c '{class, title, address}')"
    echo "cursor: $(hyprctl cursorpos)"
    hyprctl clients -j | jq -c '.[] | select(.workspace.id == ('"$(hyprctl activeworkspace -j | jq .id)"')) |
      {class, title: (.title | .[0:40]), address, floating, fullscreen, fullscreenClient, pinned, at, size, focusHistoryID, tags}'
  } >>"$OUT/timeline.txt"
  printf '.'
  sleep 1
done
echo

restore
tail -n +"$((start_line + 1))" "$LOG" >"$OUT/hyprland.log"
hyprctl clients -j >"$OUT/clients-end.json"
echo "Saved to $OUT"

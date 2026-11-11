#!/bin/bash
# A titlebar never ends up under the top bar: not when a tall window opens,
# not when a window is dragged up against the top, and not when a window comes
# back from maximized. Usage: test/run-top-bar.sh [plugin.so]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLUGIN="${1:-$ROOT/build/omarchy-macos-titlebars.so}"
source "$ROOT/../../tools/nested.sh"
source "$ROOT/../../tools/pointer.sh"
POINTER="$(build_pointer)"
NESTED_LOG="$ROOT/test/top-bar.log" nested_start "$ROOT/test/top-bar.lua" PLUGIN="$PLUGIN" STYLE="$ROOT/test/style.lua"
WAYLAND_DISPLAY="$NESTED_SOCKET" LD_PRELOAD=/usr/lib/libgtk4-layer-shell.so python3 "$ROOT/test/top-bar.py" >/dev/null 2>&1 &
PANEL=$!
trap 'kill $PANEL 2>/dev/null; nested_stop' EXIT
sleep 2

read -r W H TOP < <(hyprctl monitors -j | jq -r '.[0] | "\(.width) \(.height) \(.reserved[1])"')
BAR=28 BORDER=1
fail=0
check() { if eval "$2"; then echo "ok   $1"; else echo "FAIL $1"; fail=1; fi; }
y_of() { hyprctl clients -j | jq -r --arg c "$1" '.[] | select(.class == $c) | .at[1]'; }
# The top of the titlebar: the window's content, less the bar and its border.
bar_top() { echo $(( $(y_of "$1") - BAR - BORDER )); }
pointer() { WAYLAND_DISPLAY="$NESTED_SOCKET" "$POINTER" "$W" "$H"; }
drag_bar() { # drag_bar <class> <to y>: grab the bar's middle and pull it to y in steps
  local x y
  read -r x y < <(hyprctl clients -j | jq -r --arg c "$1" '.[] | select(.class == $c) | "\(.at[0] + .size[0] / 2 | floor) \(.at[1] - 14)"')
  { printf 'move %d %d\nwait 150\ndown\nwait 100\n' "$x" "$y"
    local step=$(( $2 < y ? -8 : 8 )) yy
    for ((yy = y; (step < 0 && yy > $2) || (step > 0 && yy < $2); yy += step)); do printf 'move %d %d\nwait 16\n' "$x" "$yy"; done
    printf 'move %d %d\nwait 300\nup\n' "$x" "$2"; } | pointer
  sleep 0.5
}
open() { hyprctl dispatch "hl.dsp.exec_cmd('foot --app-id=$1 -e sleep 600')" >/dev/null; sleep 1.5; }

check "the plugin is loaded" 'hyprctl plugin list -j | jq -e ".[] | select(.name == \"hyprbars\")" >/dev/null'
check "the panel reserves the top of the screen" '(( TOP > 0 ))'

open tall
check "a window taller than the screen opens with its bar below the panel ($(bar_top tall) >= $TOP)" '(( $(bar_top tall) >= TOP ))'

hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })' >/dev/null; sleep 0.8
hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })' >/dev/null; sleep 0.8
check "back from maximized, its bar is still below the panel ($(bar_top tall) >= $TOP)" '(( $(bar_top tall) >= TOP ))'
hyprctl dispatch 'hl.dsp.window.close()' >/dev/null; sleep 0.5

open small
drag_bar small 3
check "dragged up against the top, the bar stops at the panel ($(bar_top small) == $TOP)" '(( $(bar_top small) == TOP ))'
drag_bar small 200
check "dragged down again, the window follows the pointer ($(bar_top small) > $TOP + 100)" '(( $(bar_top small) > TOP + 100 ))'

nested_alive && echo "ok   nested Hyprland still running" || { echo "FAIL nested Hyprland crashed"; fail=1; }
exit $fail

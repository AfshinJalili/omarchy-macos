#!/bin/bash
# Scroll and click in Mission Control inside a nested Hyprland, with a virtual pointer:
# a trackpad stroke steps one workspace, a short one none, a mouse wheel one
# per notch, and a stroke past the last workspace does not wrap. Clicking a
# workspace card leaves Mission Control for that workspace. Dragging a window onto another
# workspace's card leaves the keyboard with a window still on screen.
# Usage: test/run-input.sh [plugin.so]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/../../tools/nested.sh"
source "$ROOT/../../tools/pointer.sh"
POINTER="$(build_pointer)"
NESTED_LOG="$ROOT/test/input.log" nested_start "$ROOT/test/input.lua" \
  MISSION_CONTROL_PLUGIN="${1:-$ROOT/build/omarchy-macos-mission-control.so}"
socket="$NESTED_SOCKET"
run() { hyprctl eval "$1" >/dev/null; sleep "${2:-1}"; }
for ws in 1 2 3; do
  run "hl.dispatch(hl.dsp.focus({ workspace = \"$ws\" }))" 0.5
  run 'hl.dispatch(hl.dsp.exec_cmd("foot -e sleep 600"))' 1.5
done
read -r W H < <(hyprctl monitors -j | jq -r '.[0] | "\(.width) \(.height)"')
pointer() { WAYLAND_DISPLAY="$socket" "$POINTER" "$W" "$H"; }
active() { hyprctl activeworkspace -j | jq -r .id; }
fail=0
check() { # check <name> <expected workspace>
  run 'hl.plugin.mission_control.close()' 1
  local got; got=$(active)
  if [[ $got == "$2" ]]; then echo "ok   $1: workspace $got"; else echo "FAIL $1: workspace $got, expected $2"; fail=1; fi
}
open_on() { # open Mission Control on a workspace, pointer over the main area
  run "hl.dispatch(hl.dsp.focus({ workspace = \"$1\" }))" 1
  run 'hl.plugin.mission_control.open()' 1
  printf 'move %d %d\n' $((W / 2)) $((H * 2 / 3)) | pointer
}
stroke() { # stroke <axis> <delta per event> <events>
  { for _ in $(seq "$3"); do echo "scroll $1 $2"; echo "wait 8"; done; echo "stop $1"; } | pointer
  sleep 0.6
}

open_on 1; stroke 0 5 20;                        check "one trackpad stroke steps once" 2
open_on 2; stroke 0 5 6; stroke 0 -5 20;         check "a short stroke does nothing, then back one" 1
open_on 1; stroke 1 5 20;                        check "a horizontal stroke steps once" 2
open_on 3; stroke 0 5 20;                        check "a stroke past the last workspace stays" 3
open_on 1; printf 'wheel 0 1\nwait 100\nwheel 0 1\n' | pointer; sleep 0.6; check "a mouse wheel steps per notch" 3
click() { # click <x> <y> as fractions of the screen in hundredths: card centres in the default top strip
  printf 'move %d %d\nwait 100\ndown\nwait 60\nup\n' $((W * $1 / 100)) $((H * $2 / 100)) | pointer
  sleep 1.2
}
closed_on() { # closed_on <name> <expected>: the click alone must have closed Mission Control
  local got; got=$(active)
  if [[ $got == "$2" ]]; then echo "ok   $1: workspace $got"; else echo "FAIL $1: workspace $got, expected $2"; fail=1; fi
}
open_on 1; click 59 18;                          closed_on "clicking workspace 3's card leaves for it" 3
open_on 3; click 41 18;                          closed_on "clicking workspace 2's card leaves for it" 2

# A window of one colour, to find on screen.
open_coloured() { # open_coloured <app id> <rrggbb> <workspace>
  run "hl.dispatch(hl.dsp.focus({ workspace = \"$3\" }))" 0.5
  run "hl.dispatch(hl.dsp.exec_cmd(\"foot --app-id $1 -o colors-dark.background=$2 -o colors-light.background=$2 -o colors-dark.alpha=1 -o colors-light.alpha=1 sleep 600\"))" 1.5
}
find_colour() { # find_colour <rrggbb> <row %>...: x y of a pixel of that colour, a little inside it
  local c="$1" y; shift
  for y in "$@"; do
    y=$((H * y / 100))
    WAYLAND_DISPLAY="$socket" grim -s 1 -g "0,$y ${W}x1" -t ppm - | tail -c $((W * 3)) | od -An -v -tx1 |
      tr -s ' \n' '\n' | grep -v '^$' | paste -d '' - - - | awk -v c="$c" -v y="$y" '$1 == c { print NR + 5, y; f = 1; exit } END { exit !f }' && return 0
  done
  return 1
}
drag() { # drag <x> <y> <to x> <to y>: press, move there in steps, release
  printf 'move %d %d\nwait 80\nmove %d %d\nwait 150\ndown\nwait 80\nmove %d %d\nwait 80\nmove %d %d\nwait 80\nmove %d %d\nwait 80\nup\n' \
    $(($1 + 3)) $(($2 + 3)) "$1" "$2" $((($1 * 2 + $3) / 3)) $((($2 * 2 + $4) / 3)) $((($1 + $3 * 2) / 3)) $((($2 + $4 * 2) / 3)) "$3" "$4" | pointer
  sleep 1
}
focused() { hyprctl activewindow -j | jq -r '.class // "none"'; }
workspace_of() { hyprctl clients -j | jq -r --arg c "$1" '.[] | select(.class == $c) | .workspace.id'; }
expect() { # expect <name> <got> <expected>
  if [[ $2 == "$3" ]]; then echo "ok   $1: $2"; else echo "FAIL $1: $2, expected $3"; fail=1; fi
}
open_coloured dropped ff0000 4; open_coloured stays 0000ff 4; open_coloured there 00ff00 5
run 'hl.dispatch(hl.dsp.focus({ workspace = "4" }))'
run 'hl.dispatch(hl.dsp.focus({ window = "class:^dropped$" }))'   # as the window one goes to drag is
run 'hl.plugin.mission_control.open()'
if tile=$(find_colour ff0000 40 50 60 70) && card=$(find_colour 00ff00 10 12 14 16); then
  drag $tile $card   # hovering the tile on the way focuses its window, as a hand does
  run 'hl.plugin.mission_control.close()'
  expect "the dragged window lands on the card's workspace" "$(workspace_of dropped)" 5
  expect "the keyboard stays with a window on screen, not the one dropped away" "$(focused)" stays
  run 'hl.dispatch(hl.dsp.window.move({ workspace = "6", follow = false }))'   # Super + Shift + N
  expect "moving the active window moves the one on screen" "$(workspace_of stays) $(workspace_of dropped)" "6 5"
else
  echo "FAIL no tile or card to drag between"; fail=1
  run 'hl.plugin.mission_control.close()'
fi
nested_alive && echo "alive" || { echo CRASHED; fail=1; }
exit $fail

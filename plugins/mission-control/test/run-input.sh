#!/bin/bash
# Scroll and click in Mission Control inside a nested Hyprland, with a virtual pointer:
# a trackpad stroke steps one workspace, a short one none, a mouse wheel one
# per notch, and a stroke past the last workspace does not wrap. Clicking a
# workspace card leaves Mission Control for that workspace.
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
nested_alive && echo "alive" || { echo CRASHED; fail=1; }
exit $fail

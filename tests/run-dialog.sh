#!/bin/bash
# A modal dialog opened over a maximized window must take clicks.
# Usage: tests/run-dialog.sh [plugin.so ...]
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../tools/nested.sh"
source "$HERE/../tools/pointer.sh"
POINTER="$(build_pointer)"
NESTED_LOG="$HERE/dialog.log" nested_start "$HERE/dialog.lua" PLUGINS="'$*'" STYLE="$HERE/../plugins/titlebars/test/style.lua" MODE="${MODE:-preferred}" ${OMARCHY_DIALOG_RULES:+OMARCHY_DIALOG_RULES=1}
run() { hyprctl eval "$1" >/dev/null; sleep "${2:-1}"; }
read -r W H < <(hyprctl monitors -j | jq -r '.[0] | "\(.width) \(.height)"')
pointer() { WAYLAND_DISPLAY="$NESTED_SOCKET" "$POINTER" "$W" "$H"; }
click_on() { # click the window titled $1: its centre, or with "corner" 40px in from its top left
  local x y
  read -r x y < <(hyprctl clients -j | jq -r --arg t "$1" --arg c "${2:-}" '.[] | select(.title == $t) |
    if $c == "corner" then "\(.at[0] + 40) \(.at[1] + 60)" else "\(.at[0] + .size[0] / 2 | floor) \(.at[1] + .size[1] / 2 | floor)" end')
  printf 'move %d %d\nwait 100\ndown\nwait 60\nup\n' "$x" "$y" | pointer
  sleep 0.8
}
focused() { hyprctl activewindow -j | jq -r .title; }
state() { hyprctl clients -j | jq -c '.[] | {title, floating, fullscreen, at, size}'; }

OUT="$HERE/dialog-app.out"; rm -f "$OUT"
if [[ ${STANDALONE:-0} == 1 ]]; then
  # The dialog comes from another program, as a portal file picker or a crash popup does.
  run "hl.dispatch(hl.dsp.exec_cmd(\"python3 $HERE/dialog-app.py 0 --parent-only\"))" 2
  run "hl.dispatch(hl.dsp.exec_cmd(\"python3 $HERE/dialog-app.py 4000 --standalone > $OUT 2>&1\"))" 0.5
else
  run "hl.dispatch(hl.dsp.exec_cmd(\"python3 $HERE/dialog-app.py 4000 > $OUT 2>&1\"))" 2
fi
[[ ${MAXIMIZE:-1} == 1 ]] && run 'hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized" }))' 1
sleep 3
state
echo "focused after the dialog opens: $(focused)"
click_on Dialog
echo "focused after clicking Cancel: $(focused)"
grep -q "cancel clicked" "$OUT" && echo "PASS: the dialog took the click" || echo "FAIL: the dialog ignored the click"
nested_alive && echo alive || echo CRASHED

#!/bin/bash
# Load Omarchy's plugin, then switch to ours with a config reload (or the other
# way with "reverse"), and report whether the nested Hyprland survives.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
[[ ${1:-} == reverse ]] && touch "$ROOT/test/.swap" || rm -f "$ROOT/test/.swap"
source "$ROOT/../../tools/nested.sh"
NESTED_LOG="$ROOT/test/swap.log" nested_start "$ROOT/test/swap.lua" HYPRBARS_ROOT="$ROOT"
sig="$NESTED_SIG" socket="$NESTED_SOCKET" pid="$NESTED_PID"
sleep 2; echo "before: $(hyprctl plugin list -j | jq -c "[.[] | .version]")"
[[ ${1:-} == reverse ]] && rm -f "$ROOT/test/.swap" || touch "$ROOT/test/.swap"
hyprctl reload >/dev/null; sleep 3
if kill -0 $pid 2>/dev/null; then echo "alive after swap"; else echo "CRASHED"; fi
echo "after: $(hyprctl plugin list -j | jq -c "[.[] | .version]")"
hyprctl configerrors 2>&1 | head -5
echo "options: enabled=$(hyprctl getoption plugin:hyprbars:enabled | head -1)"
echo "lua: hl.plugin.hyprbars is a $(hyprctl repl 'return type(hl.plugin.hyprbars)')"
echo "bars on the open window: $(hyprctl decorations class:foot | grep -c Hyprbar)"
if [[ -n ${2:-} ]]; then eval "$2"; sleep 3; echo "after fix: $(hyprctl plugin list -j | jq -c "[.[] | .version]") enabled=$(hyprctl getoption plugin:hyprbars:enabled | head -1)"; kill -0 $pid && echo alive || echo CRASHED; fi
kill $pid 2>/dev/null; rm -f "$ROOT/test/.swap"

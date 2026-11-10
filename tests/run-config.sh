#!/bin/bash
# Load the whole config in a nested Hyprland, with the plugins install.sh put
# in ~/.local/lib/omarchy-macos, and check each feature arrives; then again
# with Mission Control switched off in settings.lua.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
source "$REPO/tools/nested.sh"

tree=$(mktemp -d)
trap 'nested_stop; rm -rf "$tree"' EXIT
mkdir -p "$tree/hypr/macos"
ln -s "$REPO/config/macos.lua" "$tree/hypr/macos.lua"
for module in "$REPO"/config/macos/*.lua; do ln -s "$module" "$tree/hypr/macos/"; done

fail=0
check() { if eval "$2"; then echo "ok   $1"; else echo "FAIL $1"; fail=1; fi; }

session() { # session <settings.lua body>
  printf '%s\n' "$1" >"$tree/hypr/macos/settings.lua"
  NESTED_LOG="$HERE/config.log" nested_start "$HERE/config.lua" CONFIG_TREE="$tree"
  trap 'nested_stop; rm -rf "$tree"' EXIT
  sleep 1
}

session 'return {}'
plugins=$(hyprctl plugin list -j)
check "the config loads without errors" '[[ -z $(hyprctl configerrors | tr -d "[:space:]") ]]'
check "the titlebars plugin is ours" 'jq -e ".[] | select(.name == \"hyprbars\" and (.author | test(\"Afshin\")))" <<<"$plugins" >/dev/null'
check "Mission Control loads" 'jq -e ".[] | select(.name == \"mission-control\")" <<<"$plugins" >/dev/null'
check "Ctrl + Up opens Mission Control" 'hyprctl binds -j | jq -e ".[] | select(.description == \"Mission Control\" and .modmask == 4)" >/dev/null'
hyprctl eval 'hl.dispatch(hl.dsp.exec_cmd("foot -e sleep 600"))' >/dev/null; sleep 2
check "a window on a floating workspace gets a titlebar" '[[ $(hyprctl decorations class:foot | grep -c Hyprbar) -ge 1 ]]'
check "the look applies (rounding 12)" '[[ $(hyprctl getoption decoration:rounding | head -1) == "int: 12" ]]'
nested_stop

session 'return { mission_control = false, look = false }'
check "switched off, Mission Control stays out" '! hyprctl plugin list -j | jq -e ".[] | select(.name == \"mission-control\")" >/dev/null'
check "switched off, the look stays out" '[[ $(hyprctl getoption decoration:rounding | head -1) != "int: 12" ]]'
check "and the config still loads without errors" '[[ -z $(hyprctl configerrors | tr -d "[:space:]") ]]'
exit $fail

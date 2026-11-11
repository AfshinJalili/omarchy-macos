#!/bin/bash
# Reproduce the stale stock hyprbars that Undercover's own plugin juggling left
# behind, and find the smallest thing that clears it without a fresh login.
#
# Runs only in a nested Hyprland: the live session must never have a plugin
# unloaded underneath it.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
source "$REPO/tools/nested.sh"

tree=$(mktemp -d)
trap 'nested_stop; rm -rf "$tree"' EXIT
mkdir -p "$tree/hypr/macos"
ln -s "$REPO/config/macos.lua" "$tree/hypr/macos.lua"
for module in "$REPO"/config/macos/*.lua; do ln -s "$module" "$tree/hypr/macos/"; done
printf 'return {}\n' >"$tree/hypr/macos/settings.lua"

STOCK=/usr/lib/omarchy-hyprland-titlebars/titlebars.so

bars() { hyprctl plugin list -j | jq -r '[.[]|select(.name=="hyprbars")|.version]|sort|join(" + ")'; }

NESTED_LOG="$HERE/config.log" nested_start "$HERE/config.lua" CONFIG_TREE="$tree"
sleep 1

echo "after a clean load:            [$(bars)]"

# What Undercover's install does in a live session: load the stock plugin
# directly, outside the config, so no config pass ever declares it.
hyprctl plugin load "$STOCK" >/dev/null 2>&1 || true
sleep 0.5
echo "after 'hyprctl plugin load':   [$(bars)]"

# Does a config pass unload the plugin nothing declares?
hyprctl reload >/dev/null 2>&1
sleep 1.5
echo "after hyprctl reload:          [$(bars)]"

# And does a second pass catch what the first missed?
hyprctl reload >/dev/null 2>&1
sleep 1.5
echo "after a second reload:         [$(bars)]"

echo "config errors: [$(hyprctl configerrors | tr '\n' ' ')]"

# A reload leaves the undeclared copy alone, so the only thing left that does
# not need a login is unloading it by its own path. Check our plugin survives.
echo
echo "before unload:                 [$(bars)]"
hyprctl plugin unload "$STOCK" >/dev/null 2>&1 && echo "unload: ok" || echo "unload: FAILED"
sleep 0.5
echo "after unload:                  [$(bars)]"

# One titlebar per window, or none if the unload took the wrong copy with it.
hyprctl eval 'hl.dispatch(hl.dsp.exec_cmd("foot -e sleep 300"))' >/dev/null
sleep 2
echo "Hyprbar decorations on foot:   $(hyprctl decorations class:foot | grep -c '^Hyprbar')"

hyprctl reload >/dev/null 2>&1
sleep 1.5
echo "after reload:                  [$(bars)]"
echo "Hyprbar decorations again:     $(hyprctl decorations class:foot | grep -c '^Hyprbar')"
echo "config errors: [$(hyprctl configerrors | tr '\n' ' ')]"

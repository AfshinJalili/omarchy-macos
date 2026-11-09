#!/bin/bash
# Link the gestures into the Omarchy macOS config and load them from macos.lua.
set -euo pipefail

repo="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
macos="$HOME/.config/hypr/macos.lua"
line='require("hypr.macos.gestures")'

[[ -f $macos ]] || { echo "Missing $macos: this needs the Omarchy macOS config." >&2; exit 1; }

mkdir -p "$HOME/.config/hypr/macos" "$HOME/.local/bin"
ln -sfn "$repo/gestures.lua" "$HOME/.config/hypr/macos/gestures.lua"
ln -sfn "$repo/bin/omarchy-macos-app-expose" "$HOME/.local/bin/omarchy-macos-app-expose"
grep -qxF "$line" "$macos" || echo "$line" >> "$macos"

hyprctl reload >/dev/null
errors=$(hyprctl configerrors)
[[ -z ${errors//[[:space:]]/} ]] || { echo "$errors" >&2; exit 1; }
echo "macOS gestures installed."

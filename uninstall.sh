#!/bin/bash
# Remove the gestures from the Omarchy macOS config.
set -euo pipefail

sed -i '/^require("hypr.macos.gestures")$/d' "$HOME/.config/hypr/macos.lua"
rm -f "$HOME/.config/hypr/macos/gestures.lua"
hyprctl reload >/dev/null
echo "macOS gestures removed."

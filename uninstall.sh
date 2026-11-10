#!/bin/bash
# Remove omarchy-macos: the config and theme links, the plugins and the pacman
# hook. A theme in use stays applied until you pick another.
# ~/.config/hypr/macos/settings.lua and any backups stay. A running session
# keeps its plugins until the next login.
set -euo pipefail

repo="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
hypr="$HOME/.config/hypr"

# Only links into this repository are removed.
unlink_ours() {
  [[ -L $1 && $(readlink -f "$1") == "$repo"/* ]] && rm -f "$1"
  return 0
}

unlink_ours "$hypr/macos.lua"
for link in "$hypr"/macos/*.lua; do
  unlink_ours "$link"
done
for link in "$HOME"/.config/omarchy/themes/*; do
  unlink_ours "$link"
done
sed -i '/^require("hypr.macos")$/d' "$hypr/hyprland.lua"
rm -rf "$HOME/.local/lib/omarchy-macos"
"$repo/scripts/install-pacman-hook.sh" --remove

hyprctl reload >/dev/null
echo "omarchy-macos removed. Your settings are still in $hypr/macos/settings.lua."

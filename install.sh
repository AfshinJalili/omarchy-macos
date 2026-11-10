#!/bin/bash
# Install omarchy-macos for the current user:
#   * build both plugins for the installed Hyprland into ~/.local/lib/omarchy-macos/
#   * link the config into ~/.config/hypr/ (macos.lua and the modules in macos/)
#   * create ~/.config/hypr/macos/settings.lua, the on/off switches, unless it exists
#   * load it from hyprland.lua
#   * install a pacman hook that rebuilds the plugins after Hyprland upgrades
# Files it replaces are moved to ~/.config/hypr/macos/backup-<time>/.
#
# Usage: ./install.sh [--no-hook]
set -euo pipefail

repo="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
hypr="$HOME/.config/hypr"
backup="$hypr/macos/backup-$(date +%Y%m%d-%H%M%S)"

for tool in cmake git jq pkg-config hyprctl; do
  command -v "$tool" >/dev/null || { echo "omarchy-macos needs $tool" >&2; exit 1; }
done

# Move a file aside unless it is already one of our links.
set_aside() {
  local path="$1"
  if [[ -L $path ]]; then
    rm -f "$path"
  elif [[ -e $path ]]; then
    mkdir -p "$backup"
    mv "$path" "$backup/"
  fi
}

"$repo/scripts/build-plugins.sh"

mkdir -p "$hypr/macos"
set_aside "$hypr/macos.lua"
ln -s "$repo/config/macos.lua" "$hypr/macos.lua"
for module in "$repo"/config/macos/*.lua; do
  set_aside "$hypr/macos/$(basename "$module")"
  ln -s "$module" "$hypr/macos/$(basename "$module")"
done
[[ -e $hypr/macos/settings.lua ]] || cp "$repo/config/macos/defaults.lua" "$hypr/macos/settings.lua"

# Left behind by the separate gestures, hyprbars-macos and gloview installs
# this package replaces.
set_aside "$hypr/macos/gloview.lua"
rm -rf "$HOME/.local/lib/gloview" "$HOME/.local/lib/hyprbars-macos"

line='require("hypr.macos")'
grep -qxF "$line" "$hypr/hyprland.lua" || echo "$line" >>"$hypr/hyprland.lua"

[[ ${1:-} == --no-hook ]] || "$repo/scripts/install-pacman-hook.sh"

[[ -d $backup ]] && echo "Replaced files are in $backup"

# A reload applies the config now. A session that is already running the old
# hyprbars-macos or gloview plugins keeps them until the next login (the
# config checks for them), and the new plugins load then.
hyprctl reload >/dev/null
errors=$(hyprctl configerrors)
[[ -z ${errors//[[:space:]]/} ]] || { echo "$errors" >&2; exit 1; }
echo "omarchy-macos installed. Switch features on or off in $hypr/macos/settings.lua."

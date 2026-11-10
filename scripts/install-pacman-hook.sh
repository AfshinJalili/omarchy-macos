#!/bin/bash
# Install a pacman hook that rebuilds the plugins whenever Hyprland is
# installed or upgraded, for the user running this script, and remove the hook
# hyprbars-macos used to install. Remove it with scripts/install-pacman-hook.sh --remove.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
HOOK=/etc/pacman.d/hooks/omarchy-macos.hook

sudo rm -f /etc/pacman.d/hooks/hyprbars-macos.hook
if [[ ${1:-} == --remove ]]; then
  sudo rm -f "$HOOK"
  echo "Removed $HOOK"
  exit 0
fi

sudo mkdir -p "$(dirname "$HOOK")"
sudo tee "$HOOK" >/dev/null <<HOOK
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = hyprland

[Action]
Description = Rebuilding omarchy-macos plugins for the new Hyprland...
When = PostTransaction
Exec = /usr/bin/runuser -u $USER -- /usr/bin/env HOME=$HOME $REPO/scripts/build-plugins.sh
HOOK
echo "Installed $HOOK"

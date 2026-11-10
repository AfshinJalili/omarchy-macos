#!/bin/bash
# Install a pacman hook that rebuilds the plugin whenever Hyprland is installed
# or upgraded, for the user running this script. Remove it with:
#   sudo rm /etc/pacman.d/hooks/hyprbars-macos.hook
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
HOOK=/etc/pacman.d/hooks/hyprbars-macos.hook

sudo mkdir -p "$(dirname "$HOOK")"
sudo tee "$HOOK" >/dev/null <<EOF
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = hyprland

[Action]
Description = Rebuilding hyprbars-macos for the new Hyprland...
When = PostTransaction
Exec = /usr/bin/runuser -u $USER -- /usr/bin/env HOME=$HOME $REPO/scripts/rebuild-for-hyprland.sh
EOF
echo "Installed $HOOK"

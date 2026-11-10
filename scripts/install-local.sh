#!/bin/bash
# Build and install hyprbars-macos for the current user, then load the new
# build into the running Hyprland.
#
# The old file is removed before the new one is copied: Hyprland has it mapped,
# and overwriting a loaded library in place can crash the compositor. Removing
# it leaves the running copy intact until the plugin is unloaded.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$HOME/.local/lib/hyprbars-macos/hyprbars-macos.so"

cmake -B "$ROOT/build" -S "$ROOT" -DCMAKE_BUILD_TYPE=Release >/dev/null
cmake --build "$ROOT/build" -j"$(nproc)"

mkdir -p "$(dirname "$DEST")"
rm -f "$DEST"
cp "$ROOT/build/hyprbars-macos.so" "$DEST"

# Unload, then let the config load the new build. Loading it alongside the old
# one would register the same plugin:hyprbars options twice.
if hyprctl plugin list 2>/dev/null | grep -q "Version: macos-"; then
  hyprctl plugin unload "$DEST" >/dev/null || true
fi
hyprctl reload >/dev/null
sleep 2
hyprctl configerrors
hyprctl plugin list | grep -E "Version"
echo "enabled: $(hyprctl getoption plugin:hyprbars:enabled | head -1)"

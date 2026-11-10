#!/bin/bash
# Build and install the plugin for the Hyprland now installed, choosing the
# plugin commit the way hyprpm does: the pin hyprpm.toml (on main) gives for
# the installed Hyprland's commit, otherwise main.
#
# Run by the pacman hook after a Hyprland upgrade, as the user who owns this
# repository. It installs without loading: the running Hyprland is still the
# old one, so the new build is picked up at the next login.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$HOME/.local/lib/hyprbars-macos/hyprbars-macos.so"
LOG="$HOME/.cache/hyprbars-macos/rebuild.log"
mkdir -p "$(dirname "$LOG")"

commit=$(Hyprland --version | sed -n 's/.* at commit \([0-9a-f]\{40\}\).*/\1/p' | head -1)
[[ -n $commit ]] || { echo "hyprbars-macos: cannot read the installed Hyprland's commit" >&2; exit 1; }

# Pins the daily CI job adds land on GitHub; use them when online, the local
# main otherwise.
git -C "$REPO" fetch -q origin 2>/dev/null || true
manifest_ref=main
git -C "$REPO" rev-parse -q --verify origin/main >/dev/null && manifest_ref=origin/main
pin=$(git -C "$REPO" show "$manifest_ref:hyprpm.toml" | sed -n "s/.*\"$commit\", *\"\([0-9a-f]\{40\}\)\".*/\1/p" | head -1)
rev="${pin:-$manifest_ref}"
echo "hyprbars-macos: Hyprland $commit -> plugin $rev"

src=$(mktemp -d)
trap 'rm -rf "$src"' EXIT
git -C "$REPO" archive "$rev" | tar -x -C "$src"
# Compiler output goes to the log; pacman shows only the outcome.
if ! { cmake -S "$src" -B "$src/build" -DCMAKE_BUILD_TYPE=Release && cmake --build "$src/build" -j"$(nproc)"; } >"$LOG" 2>&1; then
  echo "hyprbars-macos: build failed, see $LOG. Omarchy's titlebars stay in use." >&2
  exit 1
fi

# Remove before copying: a running Hyprland may have the old build mapped, and
# overwriting a loaded library in place can crash it.
mkdir -p "$(dirname "$DEST")"
rm -f "$DEST"
cp "$src/build/hyprbars-macos.so" "$DEST"
echo "hyprbars-macos: installed $DEST; it loads at the next login"

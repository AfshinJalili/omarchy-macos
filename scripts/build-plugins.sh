#!/bin/bash
# Build both plugins for the Hyprland installed now and install them to
# ~/.local/lib/omarchy-macos/, where config/macos/plugin.lua loads them from.
#
# The sources come from the commit hyprpm.toml pins for this Hyprland (the
# hyprland-0.56 branch for 0.56.x), otherwise from main, as hyprpm would
# choose. --worktree builds the working tree instead, for development.
#
# Nothing is loaded into the running Hyprland: a running session keeps the
# plugins it has, and the new builds load at the next login. The pacman hook
# (scripts/install-pacman-hook.sh) runs this after every Hyprland upgrade.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$HOME/.local/lib/omarchy-macos"
LOG="$HOME/.cache/omarchy-macos/build.log"
PLUGINS=(titlebars mission-control)
mkdir -p "$(dirname "$LOG")" "$DEST"

src=$(mktemp -d)
trap 'rm -rf "$src"' EXIT

if [[ ${1:-} == --worktree ]]; then
  echo "omarchy-macos: building the working tree"
  cp -r "$REPO/plugins" "$src/plugins"
  rm -rf "$src"/plugins/*/build
else
  commit=$(Hyprland --version | sed -n 's/.* at commit \([0-9a-f]\{40\}\).*/\1/p' | head -1)
  [[ -n $commit ]] || { echo "omarchy-macos: cannot read the installed Hyprland's commit" >&2; exit 1; }
  # Pins the daily CI job adds land on GitHub; use them when online.
  git -C "$REPO" fetch -q origin 2>/dev/null || true
  manifest=main
  git -C "$REPO" rev-parse -q --verify origin/main >/dev/null && manifest=origin/main
  pin=$(git -C "$REPO" show "$manifest:hyprpm.toml" | sed -n "s/.*\"$commit\", *\"\([0-9a-f]\{7,40\}\)\".*/\1/p" | head -1)
  rev="${pin:-$manifest}"
  echo "omarchy-macos: Hyprland $commit -> plugins from $rev"
  git -C "$REPO" archive "$rev" plugins | tar -x -C "$src"
fi

: >"$LOG"
for plugin in "${PLUGINS[@]}"; do
  # Compiler output goes to the log; pacman shows only the outcome.
  if ! { cmake -S "$src/plugins/$plugin" -B "$src/build/$plugin" -DCMAKE_BUILD_TYPE=Release &&
    cmake --build "$src/build/$plugin" -j"$(nproc)"; } >>"$LOG" 2>&1; then
    echo "omarchy-macos: $plugin failed to build, see $LOG" >&2
    exit 1
  fi
done

for plugin in "${PLUGINS[@]}"; do
  # Remove before copying: a running Hyprland may have the old build mapped,
  # and overwriting a loaded library in place can crash it.
  rm -f "$DEST/omarchy-macos-$plugin.so"
  cp "$src/build/$plugin/omarchy-macos-$plugin.so" "$DEST/"
done
echo "omarchy-macos: installed to $DEST; the plugins load at the next login"

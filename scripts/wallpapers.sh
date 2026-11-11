#!/bin/bash
# Download Apple's macOS wallpapers for the Macos Light and Macos Dark themes.
# They are Apple's, so the repository links to them instead of shipping them.
#
#   scripts/wallpapers.sh                     list the catalog
#   scripts/wallpapers.sh [--light] <name>... download into the theme's folder
#
# Names are the first column of the list, such as tahoe-dark or sonoma-horizon.
# Wallpapers go in ~/.config/omarchy/backgrounds/macos-dark/ (or macos-light/
# with --light), where Omarchy's background switcher finds them; set one with
# omarchy theme bg set <file>.
#
# Stills come from 512 Pixels' archive of every default macOS wallpaper. Live
# wallpapers are Apple's aerial videos (the macOS screen saver and live
# wallpaper): 4K at 240 fps, around 600 MB each, too heavy to play behind the
# desktop. Each is converted once with ffmpeg to 60 fps at the height of your
# largest screen, at most 1440p.
set -euo pipefail

STILLS=https://media.512pixels.net/downloads/macos-wallpapers-6k
AERIALS=https://sylvan.apple.com/itunes-assets

# name | kind | what it is | URL
CATALOG="
big-sur-day         | still | Big Sur, day          | $STILLS/11-Big-Sur-Day-6k.jpg
big-sur-night       | still | Big Sur, night        | $STILLS/11-Big-Sur-Night-6k.jpg
big-sur-color-day   | still | Big Sur colours, day  | $STILLS/11-Big-Sur-Color-Day-6k.jpg
big-sur-color-night | still | Big Sur colours, night | $STILLS/11-Big-Sur-Color-Night-6k.jpg
monterey-light      | still | Monterey, light       | $STILLS/12-Monterey-Light.jpg
monterey-dark       | still | Monterey, dark        | $STILLS/12-Monterey-Dark.jpg
ventura-light       | still | Ventura, light        | $STILLS/13-Ventura-Light.jpg
ventura-dark        | still | Ventura, dark         | $STILLS/13-Ventura-Dark.jpg
sonoma-light        | still | Sonoma, light         | $STILLS/14-Sonoma-Light.jpg
sonoma-dark         | still | Sonoma, dark          | $STILLS/14-Sonoma-Dark.jpg
sonoma-horizon-still| still | Sonoma hills          | $STILLS/14-Sonoma-Horizon.png
sequoia-light       | still | Sequoia, light        | $STILLS/15-Sequoia-Light-6K.jpg
sequoia-dark        | still | Sequoia, dark         | $STILLS/15-Sequoia-Dark-6K.jpg
sequoia-sunrise-still| still | Sequoia forest       | $STILLS/15-Sequoia-Sunrise.png
tahoe-light         | still | Tahoe, light          | $STILLS/26-Tahoe-Light-6K.png
tahoe-dark          | still | Tahoe, dark           | $STILLS/26-Tahoe-Dark-6K.png
tahoe-beach-dawn    | still | Tahoe beach, dawn     | $STILLS/26-Tahoe-Beach-Dawn.png
tahoe-beach-day     | still | Tahoe beach, day      | $STILLS/26-Tahoe-Beach-Day.png
tahoe-beach-dusk    | still | Tahoe beach, dusk     | $STILLS/26-Tahoe-Beach-Dusk.png
tahoe-beach-night   | still | Tahoe beach, night    | $STILLS/26-Tahoe-Beach-Night.png
sonoma-horizon      | live  | Flying over the Sonoma hills and forest | $AERIALS/Aerials116/v4/cb/5b/50/cb5b5035-6701-619f-9065-3d7d0e5fbef4/W010_C003_V52_FRC_sdr_4k_qp25_240p_t2160_grover401_tsa.mov
sonoma-evening      | live  | Sonoma green hills, evening           | $AERIALS/Aerials126/v4/ec/eb/c8/ecebc8d2-5486-c2b2-52ae-6f0ab2d6b65f/S013_C001_F01_FRC240fps_sdr_4k_qp20_240p_t2160_tsa.mov
sonoma-clouds       | live  | Sonoma, above the clouds              | $AERIALS/Aerials126/v4/ec/eb/c8/ecebc8d2-5486-c2b2-52ae-6f0ab2d6b65f/S011_C003_F01_FRC240fps_sdr_4k_qp18_240p_t2160_grover401_tsa.mov
sonoma-from-above   | live  | Sonoma forest in fog                  | $AERIALS/Aerials126/v4/ec/eb/c8/ecebc8d2-5486-c2b2-52ae-6f0ab2d6b65f/S009_C018_F01_FRC240fps_sdr_4k_qp18_240p_t2160_tsa.mov
sonoma-river        | live  | Sonoma river valley                   | $AERIALS/Aerials126/v4/ec/eb/c8/ecebc8d2-5486-c2b2-52ae-6f0ab2d6b65f/S005_C013_F01_FRC240fps_sdr_4k_qp18_240p_t2160_tsa.mov
sequoia-sunrise     | live  | Sequoia forest, sunrise               | $AERIALS/Aerials116/v4/cb/5b/50/cb5b5035-6701-619f-9065-3d7d0e5fbef4/A007C0001_Final_v2_HEVC.mov
sequoia-morning     | live  | Sequoia forest, morning               | $AERIALS/Aerials116/v4/cb/5b/50/cb5b5035-6701-619f-9065-3d7d0e5fbef4/A010C0005_Final_v2_HEVC.mov
sequoia-night       | live  | Sequoia forest, night                 | $AERIALS/Aerials116/v4/cb/5b/50/cb5b5035-6701-619f-9065-3d7d0e5fbef4/A018C0002_Final_v2_HEVC.mov
"

# Apple serves its aerials under its own root certificate, which Linux doesn't
# trust. It is fetched from apple.com and checked against Apple's published
# SHA-256 fingerprint, so the downloads are still verified.
APPLE_ROOT_SHA256=B0:B1:73:0E:CB:C7:FF:45:05:14:2C:49:F1:29:5E:6E:DA:6B:CA:ED:7E:2C:68:C5:BE:91:B5:A1:10:01:F0:24
apple_root() {
  local pem="${XDG_CACHE_HOME:-$HOME/.cache}/omarchy-macos/apple-root-ca.pem"
  if [[ ! -s $pem ]]; then
    mkdir -p "$(dirname "$pem")"
    curl -fsSL https://www.apple.com/appleca/AppleIncRootCertificate.cer | openssl x509 -inform der -out "$pem"
  fi
  [[ $(openssl x509 -in "$pem" -noout -fingerprint -sha256) == *"=$APPLE_ROOT_SHA256" ]] || {
    rm -f "$pem"
    echo "Apple's root certificate did not match its fingerprint" >&2
    exit 1
  }
  echo "$pem"
}

field() { cut -d'|' -f"$1" <<<"$2" | xargs; }

if [[ $# -eq 0 ]]; then
  printf '%-22s %-6s %s\n' NAME KIND WHAT
  while IFS= read -r line; do
    [[ -n $line ]] && printf '%-22s %-6s %s\n' "$(field 1 "$line")" "$(field 2 "$line")" "$(field 3 "$line")"
  done <<<"$CATALOG"
  exit 0
fi

theme=macos-dark
[[ $1 == --light ]] && { theme=macos-light; shift; }
dir="$HOME/.config/omarchy/backgrounds/$theme"
mkdir -p "$dir"

for name in "$@"; do
  line=$(grep -E "^$name *\|" <<<"$CATALOG") || { echo "No wallpaper called $name; run without arguments for the list" >&2; exit 1; }
  kind=$(field 2 "$line")
  url=$(field 4 "$line")

  if [[ $kind == still ]]; then
    target="$dir/$name.${url##*.}"
    echo "Downloading $name"
    curl -fL --progress-bar --retry 5 --retry-all-errors -o "$target.part" "$url"
  else
    command -v ffmpeg >/dev/null || { echo "Live wallpapers need ffmpeg" >&2; exit 1; }
    target="$dir/$name.mp4"
    source="$dir/.$name.mov"
    echo "Downloading $name (about 600 MB, once)"
    curl -fL --progress-bar --retry 20 --retry-all-errors --retry-delay 2 --cacert "$(apple_root)" -C - -o "$source" "$url"
    height=$(hyprctl monitors -j 2>/dev/null | jq 'map(.height) | max // 1440' 2>/dev/null || echo 1440)
    (( height <= 1440 )) || height=1440
    echo "Converting $name to ${height}p at 60 fps"
    ffmpeg -loglevel error -stats -y -i "$source" -an -vf "scale=-2:$height,fps=60" \
      -c:v libx264 -preset medium -crf 23 -pix_fmt yuv420p -movflags +faststart -f mp4 "$target.part"
    rm -f "$source"
  fi
  mv "$target.part" "$target"
  echo "Saved $target"
done
echo "Set one with: omarchy theme bg set <file>, or pick it in Omarchy's background switcher."

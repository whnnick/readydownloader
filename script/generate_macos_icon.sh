#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_ICON="$ROOT_DIR/assets/branding/AppIcon.png"
OUTPUT_ICON="${1:-$ROOT_DIR/dist/AppIcon.icns}"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/ytdlp-icon.XXXXXX")"
ICON_DIR="$WORK_DIR/png"
trap 'rm -rf "$WORK_DIR"' EXIT

[[ -s "$SOURCE_ICON" ]] || {
  echo "Missing app icon source: $SOURCE_ICON" >&2
  exit 1
}

width="$(sips -g pixelWidth "$SOURCE_ICON" | awk '/pixelWidth/ { print $2 }')"
height="$(sips -g pixelHeight "$SOURCE_ICON" | awk '/pixelHeight/ { print $2 }')"
has_alpha="$(sips -g hasAlpha "$SOURCE_ICON" | awk '/hasAlpha/ { print $2 }')"
[[ "$width" == "1024" && "$height" == "1024" && "$has_alpha" == "yes" ]] || {
  echo "App icon source must be a 1024x1024 PNG with alpha." >&2
  exit 1
}

mkdir -p "$ICON_DIR" "$(dirname "$OUTPUT_ICON")"
sizes=(
  "16:icon_16x16.png"
  "32:icon_32x32.png"
  "64:icon_64x64.png"
  "128:icon_128x128.png"
  "256:icon_256x256.png"
  "512:icon_512x512.png"
  "1024:icon_1024x1024.png"
)

for entry in "${sizes[@]}"; do
  size="${entry%%:*}"
  name="${entry#*:}"
  sips -z "$size" "$size" "$SOURCE_ICON" --out "$ICON_DIR/$name" >/dev/null
done

python3 "$ROOT_DIR/script/build_icns.py" "$ICON_DIR" "$OUTPUT_ICON"
echo "Generated macOS icon: $OUTPUT_ICON"

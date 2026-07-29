#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="YouTubeDlpDownloader"
VERSION="$(tr -d '[:space:]' < "$ROOT_DIR/VERSION")"
RELEASE_DIR="$ROOT_DIR/dist/release"
ZIP_PATH="$RELEASE_DIR/$APP_NAME-$VERSION-macos-arm64.zip"
DMG_PATH="$RELEASE_DIR/$APP_NAME-$VERSION-macos-arm64.dmg"
EXPECTED_FILES=3

[[ -s "$ZIP_PATH" && -s "$DMG_PATH" && -s "$RELEASE_DIR/SHA256SUMS.txt" ]]
actual_files="$(find "$RELEASE_DIR" -maxdepth 1 -type f | wc -l | tr -d '[:space:]')"
[[ "$actual_files" == "$EXPECTED_FILES" ]] || {
  echo "Release directory must contain exactly $EXPECTED_FILES files; found $actual_files." >&2
  exit 1
}

(
  cd "$RELEASE_DIR"
  shasum -a 256 -c SHA256SUMS.txt
)
hdiutil verify "$DMG_PATH"

WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/ytdlp-release.XXXXXX")"
MOUNT_DIR="$WORK_DIR/mount"
mkdir -p "$MOUNT_DIR"
mounted=0
cleanup() {
  if [[ "$mounted" == "1" ]]; then
    hdiutil detach "$MOUNT_DIR" -quiet || true
  fi
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

ditto -x -k "$ZIP_PATH" "$WORK_DIR/zip"
ZIP_APP="$WORK_DIR/zip/$APP_NAME.app"
[[ -d "$ZIP_APP" ]]

hdiutil attach "$DMG_PATH" -nobrowse -readonly -mountpoint "$MOUNT_DIR" -quiet
mounted=1
[[ -d "$MOUNT_DIR/$APP_NAME.app" && -L "$MOUNT_DIR/Applications" ]]

bundle_version="$(plutil -extract CFBundleShortVersionString raw "$ZIP_APP/Contents/Info.plist")"
[[ "$bundle_version" == "$VERSION" ]]

if find "$ZIP_APP" -type l | grep . >/dev/null; then
  echo "Release app contains symlinks." >&2
  exit 1
fi

if find "$ZIP_APP" \( -name ".codex" -o -name ".agents" -o -name "AGENTS.md" \
  -o -name "*.pdb" -o -name "*.obj" -o -name "*.part" -o -name "*.cookies" \
  -o -name "yt_cookies.txt" -o -name ".env" -o -name "*.mp4" -o -name "*.webm" \
  -o -name "*.mkv" -o -name "*.mov" -o -name "*.mp3" -o -name "*.m4a" \) | grep . >/dev/null; then
  echo "Release app contains a denied file." >&2
  exit 1
fi

if strings "$ZIP_APP/Contents/MacOS/$APP_NAME" | grep -E "/Users/[^/]+|/opt/homebrew|/usr/local" >/dev/null; then
  echo "Release binary contains a developer-machine path." >&2
  exit 1
fi

TOOLS_DIR="$ZIP_APP/Contents/Resources/tools" \
TOOL_LICENSES_DIR="$ZIP_APP/Contents/Resources/licenses" \
"$ROOT_DIR/script/verify_macos_tools.sh"
codesign --verify --deep --strict --verbose=2 "$ZIP_APP"
deno_entitlements="$(codesign -d --entitlements :- "$ZIP_APP/Contents/Resources/tools/deno" 2>&1)"
grep -Fq "com.apple.security.cs.allow-jit" <<< "$deno_entitlements"
"$ZIP_APP/Contents/Resources/tools/deno" eval \
  'if (6 * 7 !== 42) Deno.exit(1)' >/dev/null

MEDIA_DIR="$WORK_DIR/media"
mkdir -p "$MEDIA_DIR"
"$ZIP_APP/Contents/Resources/tools/ffmpeg" -hide_banner -loglevel error \
  -f lavfi -i testsrc2=size=320x180:rate=30 -t 1 -c:v mpeg4 -an "$MEDIA_DIR/video.mp4"
"$ZIP_APP/Contents/Resources/tools/ffmpeg" -hide_banner -loglevel error \
  -f lavfi -i sine=frequency=1000 -t 1 -c:a aac "$MEDIA_DIR/audio.m4a"
"$ZIP_APP/Contents/Resources/tools/ffmpeg" -hide_banner -loglevel error \
  -i "$MEDIA_DIR/video.mp4" -i "$MEDIA_DIR/audio.m4a" -c copy "$MEDIA_DIR/merged.mp4"
merged_streams="$("$ZIP_APP/Contents/Resources/tools/ffprobe" -v error \
  -show_entries stream=codec_type -of csv=p=0 "$MEDIA_DIR/merged.mp4")"
grep -Fq "video" <<< "$merged_streams"
grep -Fq "audio" <<< "$merged_streams"

if [[ "${REQUIRE_GATEKEEPER:-0}" == "1" ]]; then
  codesign -dvv "$ZIP_APP" 2>&1 | grep -Eq "flags=.*runtime"
  for tool in yt-dlp deno ffmpeg ffprobe; do
    codesign -dvv "$ZIP_APP/Contents/Resources/tools/$tool" 2>&1 | grep -Eq "flags=.*runtime"
  done
  spctl --assess --type execute --verbose=2 "$ZIP_APP"
fi

echo "macOS release package verified."

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$ROOT_DIR/packaging/macos-arm64-tools.conf"
TOOLS_DIR="${TOOLS_DIR:-$ROOT_DIR/tools/macos-arm64}"
LICENSES_DIR="${TOOL_LICENSES_DIR:-$TOOLS_DIR/licenses}"
MANIFEST_STAMP="${TOOL_MANIFEST_STAMP:-$TOOLS_DIR/.manifest-sha256}"

# shellcheck source=../packaging/macos-arm64-tools.conf
source "$MANIFEST"

required_files=(yt-dlp deno ffmpeg ffprobe)
for name in "${required_files[@]}"; do
  path="$TOOLS_DIR/$name"
  if [[ ! -f "$path" || ! -x "$path" || -L "$path" ]]; then
    echo "Missing non-symlink executable: $path" >&2
    exit 1
  fi
  if ! file "$path" | grep "arm64" >/dev/null; then
    echo "Tool is not arm64: $path" >&2
    exit 1
  fi
  if otool -L "$path" | grep -E "/opt/homebrew|/usr/local" >/dev/null; then
    echo "Tool has a developer-machine dependency: $path" >&2
    exit 1
  fi
done

required_licenses=(
  yt-dlp-UNLICENSE.txt
  yt-dlp-THIRD_PARTY_LICENSES.txt
  Deno-MIT.txt
  FFmpeg-LGPL-2.1.txt
  FFmpeg-LICENSE.md
)
for name in "${required_licenses[@]}"; do
  [[ -s "$LICENSES_DIR/$name" ]] || {
    echo "Missing third-party license: $name" >&2
    exit 1
  }
done

expected_manifest_sha="$(shasum -a 256 "$MANIFEST" | awk '{print $1}')"
[[ -s "$MANIFEST_STAMP" ]] || {
  echo "Missing toolchain manifest stamp." >&2
  exit 1
}
actual_manifest_sha="$(tr -d '[:space:]' < "$MANIFEST_STAMP")"
[[ "$actual_manifest_sha" == "$expected_manifest_sha" ]] || {
  echo "Toolchain manifest stamp is stale." >&2
  exit 1
}

yt_dlp_version="$("$TOOLS_DIR/yt-dlp" --version)"
deno_version="$("$TOOLS_DIR/deno" --version 2>&1)"
ffmpeg_version="$("$TOOLS_DIR/ffmpeg" -version 2>&1)"
ffprobe_version="$("$TOOLS_DIR/ffprobe" -version 2>&1)"

[[ "$yt_dlp_version" == "$YTDLP_VERSION" ]]
grep -Fq "deno $DENO_VERSION" <<< "$deno_version"
grep -Fq "ffmpeg version $FFMPEG_VERSION" <<< "$ffmpeg_version"
grep -Fq "ffprobe version $FFMPEG_VERSION" <<< "$ffprobe_version"
"$TOOLS_DIR/ffmpeg" -hide_banner -encoders 2>&1 | grep -Fq "h264_videotoolbox"
"$TOOLS_DIR/ffmpeg" -hide_banner -encoders 2>&1 | grep -Eq "[[:space:]]aac[[:space:]]"

echo "macOS arm64 toolchain verified."

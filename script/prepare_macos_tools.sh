#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$ROOT_DIR/packaging/macos-arm64-tools.conf"
TOOLS_DIR="$ROOT_DIR/tools/macos-arm64"
FORCE="${1:-}"

# shellcheck source=../packaging/macos-arm64-tools.conf
source "$MANIFEST"

manifest_sha() {
  shasum -a 256 "$MANIFEST" | awk '{print $1}'
}

if [[ "$FORCE" != "--force" ]] &&
   [[ -x "$TOOLS_DIR/yt-dlp" && -x "$TOOLS_DIR/deno" && -x "$TOOLS_DIR/ffmpeg" && -x "$TOOLS_DIR/ffprobe" ]] &&
   [[ -f "$TOOLS_DIR/.manifest-sha256" ]] &&
   [[ "$(tr -d '[:space:]' < "$TOOLS_DIR/.manifest-sha256")" == "$(manifest_sha)" ]]; then
  "$ROOT_DIR/script/verify_macos_tools.sh"
  exit 0
fi

if [[ "$(uname -s)" != "Darwin" || "$(uname -m)" != "arm64" ]]; then
  echo "macOS arm64 is required to prepare the release toolchain." >&2
  exit 1
fi

WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/ytdlp-tools.XXXXXX")"
trap 'rm -rf "$WORK_DIR"' EXIT

download() {
  local url="$1"
  local output="$2"
  curl -fL --retry 3 --retry-delay 2 "$url" -o "$output"
}

verify_sha256() {
  local expected="$1"
  local file="$2"
  local actual
  actual="$(shasum -a 256 "$file" | awk '{print $1}')"
  if [[ "$actual" != "$expected" ]]; then
    echo "SHA-256 mismatch for $(basename "$file"): expected $expected, got $actual" >&2
    exit 1
  fi
}

download "$YTDLP_URL" "$WORK_DIR/yt-dlp"
download "$DENO_URL" "$WORK_DIR/deno.zip"
download "$FFMPEG_URL" "$WORK_DIR/ffmpeg.tar.xz"
download "$YTDLP_LICENSE_URL" "$WORK_DIR/yt-dlp-LICENSE"
download "$YTDLP_THIRD_PARTY_LICENSES_URL" "$WORK_DIR/yt-dlp-THIRD_PARTY_LICENSES.txt"
download "$DENO_LICENSE_URL" "$WORK_DIR/deno-LICENSE.md"

verify_sha256 "$YTDLP_SHA256" "$WORK_DIR/yt-dlp"
verify_sha256 "$DENO_SHA256" "$WORK_DIR/deno.zip"
verify_sha256 "$FFMPEG_SHA256" "$WORK_DIR/ffmpeg.tar.xz"
verify_sha256 "$YTDLP_LICENSE_SHA256" "$WORK_DIR/yt-dlp-LICENSE"
verify_sha256 "$YTDLP_THIRD_PARTY_LICENSES_SHA256" "$WORK_DIR/yt-dlp-THIRD_PARTY_LICENSES.txt"
verify_sha256 "$DENO_LICENSE_SHA256" "$WORK_DIR/deno-LICENSE.md"

mkdir -p "$WORK_DIR/deno" "$WORK_DIR/ffmpeg-source" "$WORK_DIR/ffmpeg-prefix"
ditto -x -k "$WORK_DIR/deno.zip" "$WORK_DIR/deno"
tar -xJf "$WORK_DIR/ffmpeg.tar.xz" -C "$WORK_DIR/ffmpeg-source" --strip-components=1

CLANG="$(xcrun --find clang)"
CLANGXX="$(xcrun --find clang++)"
MACOS_SDK="$(xcrun --sdk macosx --show-sdk-path)"

(
  cd "$WORK_DIR/ffmpeg-source"
  ./configure \
    --prefix="$WORK_DIR/ffmpeg-prefix" \
    --arch=arm64 \
    --target-os=darwin \
    --cc="$CLANG" \
    --cxx="$CLANGXX" \
    --host-cc="$CLANG" \
    --sysroot="$MACOS_SDK" \
    --host-cflags="--sysroot=$MACOS_SDK" \
    --host-ldflags="--sysroot=$MACOS_SDK" \
    --disable-autodetect \
    --disable-debug \
    --disable-doc \
    --disable-ffplay \
    --disable-gpl \
    --disable-nonfree \
    --disable-shared \
    --enable-static \
    --enable-videotoolbox \
    --enable-encoder=h264_videotoolbox
  make -s -j "$(sysctl -n hw.logicalcpu)"
  make -s install
)

rm -rf "$TOOLS_DIR"
mkdir -p "$TOOLS_DIR/licenses"
install -m 755 "$WORK_DIR/yt-dlp" "$TOOLS_DIR/yt-dlp"
install -m 755 "$WORK_DIR/deno/deno" "$TOOLS_DIR/deno"
install -m 755 "$WORK_DIR/ffmpeg-prefix/bin/ffmpeg" "$TOOLS_DIR/ffmpeg"
install -m 755 "$WORK_DIR/ffmpeg-prefix/bin/ffprobe" "$TOOLS_DIR/ffprobe"
install -m 644 "$WORK_DIR/yt-dlp-LICENSE" "$TOOLS_DIR/licenses/yt-dlp-UNLICENSE.txt"
install -m 644 "$WORK_DIR/yt-dlp-THIRD_PARTY_LICENSES.txt" "$TOOLS_DIR/licenses/yt-dlp-THIRD_PARTY_LICENSES.txt"
install -m 644 "$WORK_DIR/deno-LICENSE.md" "$TOOLS_DIR/licenses/Deno-MIT.txt"
install -m 644 "$WORK_DIR/ffmpeg-source/COPYING.LGPLv2.1" "$TOOLS_DIR/licenses/FFmpeg-LGPL-2.1.txt"
install -m 644 "$WORK_DIR/ffmpeg-source/LICENSE.md" "$TOOLS_DIR/licenses/FFmpeg-LICENSE.md"
manifest_sha > "$TOOLS_DIR/.manifest-sha256"

"$ROOT_DIR/script/verify_macos_tools.sh"

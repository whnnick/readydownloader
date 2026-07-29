#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLS_DIR="${TOOLS_DIR:-$ROOT_DIR/tools/macos-arm64}"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/ytdlp-integration.XXXXXX")"
MEDIA_DIR="$WORK_DIR/media"
OUTPUT_DIR="$WORK_DIR/output"
SERVER_PID=""

cleanup() {
  if [[ -n "$SERVER_PID" ]]; then
    kill "$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true
  fi
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

"$ROOT_DIR/script/verify_macos_tools.sh"
mkdir -p "$MEDIA_DIR" "$OUTPUT_DIR"

"$TOOLS_DIR/ffmpeg" -hide_banner -loglevel error \
  -f lavfi -i testsrc2=size=320x180:rate=30 \
  -f lavfi -i sine=frequency=1000:sample_rate=48000 \
  -t 2 \
  -map 0:v:0 -map 1:a:0 \
  -c:v mpeg4 -q:v 5 \
  -c:a aac -b:a 96k \
  -f dash -use_timeline 1 -use_template 1 \
  "$MEDIA_DIR/manifest.mpd"

PORT="$(python3 -c 'import socket; s = socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1]); s.close()')"
python3 -m http.server "$PORT" \
  --bind 127.0.0.1 \
  --directory "$MEDIA_DIR" \
  >"$WORK_DIR/server.log" 2>&1 &
SERVER_PID=$!

server_ready=0
for _ in 1 2 3 4 5; do
  if curl -fsS "http://127.0.0.1:$PORT/manifest.mpd" >/dev/null 2>&1; then
    server_ready=1
    break
  fi
  sleep 1
done
if [[ "$server_ready" -ne 1 ]]; then
  cat "$WORK_DIR/server.log" >&2
  echo "Local DASH server did not become ready." >&2
  exit 1
fi

"$TOOLS_DIR/yt-dlp" \
  --ignore-config \
  --force-ipv4 \
  --js-runtimes "deno:$TOOLS_DIR/deno" \
  --ffmpeg-location "$TOOLS_DIR" \
  --no-playlist \
  --print after_move:filepath \
  -f "bv*+ba/b" \
  -P "$OUTPUT_DIR" \
  "http://127.0.0.1:$PORT/manifest.mpd" \
  >"$WORK_DIR/yt-dlp.log" 2>&1 || {
    cat "$WORK_DIR/yt-dlp.log" >&2
    exit 1
  }

output_count="$(find "$OUTPUT_DIR" -maxdepth 1 -type f | wc -l | tr -d '[:space:]')"
[[ "$output_count" == "1" ]] || {
  cat "$WORK_DIR/yt-dlp.log" >&2
  echo "Expected one merged output file, found $output_count." >&2
  exit 1
}

OUTPUT_PATH="$(find "$OUTPUT_DIR" -maxdepth 1 -type f -print -quit)"
stream_types="$("$TOOLS_DIR/ffprobe" -v error \
  -show_entries stream=codec_type \
  -of csv=p=0 \
  "$OUTPUT_PATH")"
grep -Fxq "video" <<< "$stream_types"
grep -Fxq "audio" <<< "$stream_types"

echo "Local yt-dlp best-quality download and audio merge verified."

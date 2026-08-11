#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
BUILD_CONFIGURATION="${BUILD_CONFIGURATION:-debug}"
APP_NAME="ReadyDownloader"
BUNDLE_ID="com.readydownloader.app"
MIN_SYSTEM_VERSION="13.0"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGE_DIR="$ROOT_DIR/apps/macos"
BUILD_DIR="$PACKAGE_DIR/.build"
SWIFTPM_CACHE_DIR="$BUILD_DIR/swiftpm-cache"
SWIFTPM_CONFIG_DIR="$BUILD_DIR/swiftpm-config"
SWIFTPM_SECURITY_DIR="$BUILD_DIR/swiftpm-security"
CLANG_MODULE_CACHE_DIR="$BUILD_DIR/clang-module-cache"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
LOCAL_TOOLS_DIR="$ROOT_DIR/tools/macos-arm64"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
APP_ICON="$BUILD_DIR/AppIcon.icns"
VERSION="$(tr -d '[:space:]' < "$ROOT_DIR/VERSION")"

mkdir -p "$SWIFTPM_CACHE_DIR" "$SWIFTPM_CONFIG_DIR" "$SWIFTPM_SECURITY_DIR" "$CLANG_MODULE_CACHE_DIR"
export CLANG_MODULE_CACHE_PATH="$CLANG_MODULE_CACHE_DIR"

SWIFT_BUILD_ARGS=(
  --package-path "$PACKAGE_DIR"
  --scratch-path "$BUILD_DIR"
  --cache-path "$SWIFTPM_CACHE_DIR"
  --config-path "$SWIFTPM_CONFIG_DIR"
  --security-path "$SWIFTPM_SECURITY_DIR"
  --manifest-cache local
  --disable-sandbox
  --configuration "$BUILD_CONFIGURATION"
)

swift build "${SWIFT_BUILD_ARGS[@]}" --product "$APP_NAME"
BUILD_BINARY="$(swift build "${SWIFT_BUILD_ARGS[@]}" --show-bin-path)/$APP_NAME"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS" "$APP_RESOURCES"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"
"$ROOT_DIR/script/generate_macos_icon.sh" "$APP_ICON"
cp "$APP_ICON" "$APP_RESOURCES/AppIcon.icns"
if [[ -d "$LOCAL_TOOLS_DIR" ]]; then
  mkdir -p "$APP_RESOURCES/tools"
  for tool in yt-dlp deno ffmpeg ffprobe; do
    if [[ -f "$LOCAL_TOOLS_DIR/$tool" ]]; then
      cp "$LOCAL_TOOLS_DIR/$tool" "$APP_RESOURCES/tools/$tool"
      chmod +x "$APP_RESOURCES/tools/$tool"
    fi
  done
  if [[ -f "$LOCAL_TOOLS_DIR/.manifest-sha256" ]]; then
    cp "$LOCAL_TOOLS_DIR/.manifest-sha256" "$APP_RESOURCES/tools/.manifest-sha256"
  fi
  if [[ -d "$LOCAL_TOOLS_DIR/licenses" ]]; then
    cp -R "$LOCAL_TOOLS_DIR/licenses" "$APP_RESOURCES/licenses"
  fi
fi

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key><string>$APP_NAME</string>
  <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
  <key>CFBundleName</key><string>$APP_NAME</string>
  <key>CFBundleDisplayName</key><string>$APP_NAME</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>$MIN_SYSTEM_VERSION</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSPrincipalClass</key><string>NSApplication</string>
</dict>
</plist>
PLIST

open_app() { /usr/bin/open -n "$APP_BUNDLE"; }

case "$MODE" in
  build) ;;
  run)
    pkill -x "$APP_NAME" >/dev/null 2>&1 || true
    open_app
    ;;
  --debug|debug) lldb -- "$APP_BINARY" ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    pkill -x "$APP_NAME" >/dev/null 2>&1 || true
    open_app
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  *)
    echo "usage: $0 [build|run|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac

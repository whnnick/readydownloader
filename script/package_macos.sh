#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="YouTubeDlpDownloader"
VERSION="$(tr -d '[:space:]' < "$ROOT_DIR/VERSION")"
DIST_DIR="$ROOT_DIR/dist"
RELEASE_DIR="$DIST_DIR/release"
BUILT_APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
ZIP_PATH="$RELEASE_DIR/$APP_NAME-$VERSION-macos-arm64.zip"
DMG_PATH="$RELEASE_DIR/$APP_NAME-$VERSION-macos-arm64.dmg"
SIGNING_IDENTITY="${MACOS_SIGNING_IDENTITY:--}"
ENTITLEMENTS="$ROOT_DIR/packaging/macos/YouTubeDlpDownloader.entitlements"
DENO_ENTITLEMENTS="$ROOT_DIR/packaging/macos/Deno.entitlements"
PACKAGE_WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/ytdlp-package.XXXXXX")"
APP_BUNDLE="$PACKAGE_WORK_DIR/$APP_NAME.app"
trap 'rm -rf "$PACKAGE_WORK_DIR"' EXIT

"$ROOT_DIR/script/check_release_consistency.sh"
"$ROOT_DIR/script/prepare_macos_tools.sh"

rm -rf "$RELEASE_DIR" "$BUILT_APP_BUNDLE"
mkdir -p "$RELEASE_DIR"
BUILD_CONFIGURATION=release "$ROOT_DIR/script/build_and_run.sh" build
ditto --norsrc --noextattr "$BUILT_APP_BUNDLE" "$APP_BUNDLE"
rm -rf "$BUILT_APP_BUNDLE"

mkdir -p "$APP_BUNDLE/Contents/Resources/licenses/project"
cp "$ROOT_DIR/LICENSE" "$APP_BUNDLE/Contents/Resources/licenses/project/YouTubeDlpDownloader-MIT.txt"
cp "$ROOT_DIR/THIRD_PARTY_NOTICES.md" "$APP_BUNDLE/Contents/Resources/licenses/THIRD_PARTY_NOTICES.md"
xattr -cr "$APP_BUNDLE"

sign_path() {
  local path="$1"
  local entitlements="${2:-}"
  if [[ "$SIGNING_IDENTITY" == "-" ]]; then
    if [[ -n "$entitlements" ]]; then
      codesign --force --sign - --entitlements "$entitlements" "$path"
    else
      codesign --force --sign - "$path"
    fi
  else
    if [[ -n "$entitlements" ]]; then
      codesign --force --options runtime --timestamp --sign "$SIGNING_IDENTITY" \
        --entitlements "$entitlements" "$path"
    else
      codesign --force --options runtime --timestamp --sign "$SIGNING_IDENTITY" "$path"
    fi
  fi
}

sign_path "$APP_BUNDLE/Contents/Resources/tools/yt-dlp"
sign_path "$APP_BUNDLE/Contents/Resources/tools/deno" "$DENO_ENTITLEMENTS"
sign_path "$APP_BUNDLE/Contents/Resources/tools/ffmpeg"
sign_path "$APP_BUNDLE/Contents/Resources/tools/ffprobe"

if [[ "$SIGNING_IDENTITY" == "-" ]]; then
  codesign --force --sign - --entitlements "$ENTITLEMENTS" "$APP_BUNDLE"
else
  codesign --force --options runtime --timestamp --sign "$SIGNING_IDENTITY" \
    --entitlements "$ENTITLEMENTS" "$APP_BUNDLE"
fi

codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"
plutil -lint "$APP_BUNDLE/Contents/Info.plist"

if [[ -n "${MACOS_NOTARY_PROFILE:-}" ]]; then
  if [[ "$SIGNING_IDENTITY" == "-" ]]; then
    echo "Notarization requires a Developer ID Application identity." >&2
    exit 1
  fi
  NOTARY_ZIP="$PACKAGE_WORK_DIR/$APP_NAME-notary.zip"
  ditto -c -k --keepParent "$APP_BUNDLE" "$NOTARY_ZIP"
  xcrun notarytool submit "$NOTARY_ZIP" --keychain-profile "$MACOS_NOTARY_PROFILE" --wait
  xcrun stapler staple "$APP_BUNDLE"
  xcrun stapler validate "$APP_BUNDLE"
  rm -f "$NOTARY_ZIP"
fi

ditto -c -k --sequesterRsrc --keepParent "$APP_BUNDLE" "$ZIP_PATH"

DMG_STAGE="$PACKAGE_WORK_DIR/dmg-stage"
mkdir -p "$DMG_STAGE"
cp -R "$APP_BUNDLE" "$DMG_STAGE/"
ln -s /Applications "$DMG_STAGE/Applications"
hdiutil create \
  -volname "$APP_NAME $VERSION" \
  -srcfolder "$DMG_STAGE" \
  -format UDZO \
  -ov \
  "$DMG_PATH"

if [[ "$SIGNING_IDENTITY" != "-" ]]; then
  codesign --force --timestamp --sign "$SIGNING_IDENTITY" "$DMG_PATH"
fi

if [[ -n "${MACOS_NOTARY_PROFILE:-}" ]]; then
  xcrun notarytool submit "$DMG_PATH" --keychain-profile "$MACOS_NOTARY_PROFILE" --wait
  xcrun stapler staple "$DMG_PATH"
  xcrun stapler validate "$DMG_PATH"
fi

(
  cd "$RELEASE_DIR"
  shasum -a 256 "$(basename "$ZIP_PATH")" "$(basename "$DMG_PATH")" > SHA256SUMS.txt
)

"$ROOT_DIR/script/verify_macos_release.sh"
echo "macOS release artifacts created in $RELEASE_DIR"

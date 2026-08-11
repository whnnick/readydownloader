# Release Guide

macOS is the primary release line. Windows compatibility work does not block a
Mac release unless the release is explicitly advertised as dual-platform.
The canonical GitHub repository slug is `whnnick/readydownloader`.

## Local Release Validation

Requirements:

- Apple Silicon Mac running macOS 13 or later;
- Xcode command-line tools;
- Python 3, `curl`, `make`, `tar`, `ditto`, and `hdiutil`;
- enough free space to build FFmpeg from source.

Run:

```bash
./script/prepare_macos_tools.sh
./script/package_macos.sh
```

The first command downloads pinned inputs, verifies every SHA-256, and builds
FFmpeg 8.1.2 from official source without GPL or non-free external libraries.
The build explicitly enables Apple's VideoToolbox H.264 encoder for the macOS
iPhone-compatible download mode.
The second command creates an ad-hoc-signed development package when
`MACOS_SIGNING_IDENTITY` is not set. Before packaging, it also serves locally
generated separate DASH video/audio streams, downloads them with the pinned
yt-dlp best-quality selector, verifies the merged output, converts it through
VideoToolbox, and confirms H.264, AAC, and yuv420p output with bundled FFprobe.

The build generates `AppIcon.icns` from the tracked 1024×1024 branding master.
Package verification requires both the icon resource and the matching
`CFBundleIconFile` entry.

Expected files:

```text
dist/release/
├── ReadyDownloader-<version>-macos-arm64.dmg
├── ReadyDownloader-<version>-macos-arm64.zip
└── SHA256SUMS.txt
```

The release directory is deleted before packaging and must contain exactly
those three current-version files.

## Developer ID Signing and Notarization

Store notarization credentials in the login keychain:

```bash
xcrun notarytool store-credentials ReadyDownloader-notary
```

Then run:

```bash
MACOS_SIGNING_IDENTITY="Developer ID Application: Example (TEAMID)" \
MACOS_NOTARY_PROFILE="ReadyDownloader-notary" \
REQUIRE_GATEKEEPER=1 \
./script/package_macos.sh
```

The packaging script signs nested executables first, grants only the JIT runtime
exception required by Deno, signs the app with Hardened Runtime, submits and
staples the app, creates ZIP and DMG artifacts, notarizes and staples the DMG,
verifies Gatekeeper, and generates checksums.

## GitHub Release

GitHub Releases are published from
`https://github.com/whnnick/readydownloader`. ReadySuite should use
`https://github.com/whnnick/readydownloader/releases/latest` as the product
download target.

For a Developer ID signed and notarized release, configure all of these
repository secrets:

- `MACOS_CERTIFICATE_P12_BASE64`
- `MACOS_CERTIFICATE_PASSWORD`
- `MACOS_SIGNING_IDENTITY`
- `APPLE_ID`
- `APPLE_TEAM_ID`
- `APPLE_APP_SPECIFIC_PASSWORD`

Before tagging:

1. Complete the version black-box report.
2. Change the current `VERSION` headings in both changelogs from `Unreleased` to the release date.
3. Confirm `VERSION` and the intended tag agree.
4. Commit and push a clean `main`.
5. Create and push `v<version>`.

The workflow refuses an unreleased changelog entry or partially configured
Apple credentials. With all six credentials it publishes a Developer ID signed
and notarized package. With none of them it publishes an explicitly labelled,
ad-hoc-signed and unnotarized package. After publishing, it downloads the public
assets, verifies their checksums, requires exactly three assets, and verifies
that the tag is GitHub's latest release.

### Release synchronization invariant

A release-ready version must not stop after pushing `main`. The same release
operation must push `v<version>`, publish the matching GitHub Release, upload
the ZIP, DMG, and `SHA256SUMS.txt`, and verify the public `latest` endpoint.
If any of these steps cannot complete, keep the changelog entry marked
`Unreleased` and do not advertise that version as available.

## Third-Party Components

The pinned manifest is `packaging/macos-arm64-tools.conf`.

- yt-dlp 2026.07.04: official macOS standalone binary;
- Deno 2.9.4: official Apple Silicon binary;
- FFmpeg and ffprobe 8.1.2: built from official source with no GPL or non-free
  external libraries enabled.

Each package contains the project license, third-party notices, yt-dlp's
generated third-party license collection, and the Deno and FFmpeg license
texts. The yt-dlp standalone binary contains GPLv3+ components; its license
terms apply to that bundled component.

# 0.1.0 Requirements

## Product Boundary

Version 0.1.0 is a single-item desktop downloader. It is not a media library, browser, crawler, account manager, or DRM circumvention tool.

## Supported Platforms

- Windows 10 or later, x64.
- macOS 14 or later, Apple Silicon.

Intel macOS, Linux, mobile platforms, and app-store distribution are outside this release.

## Functional Requirements

### URL and Metadata

- Accept one user-provided URL.
- Reject an empty URL before launching yt-dlp.
- Query metadata using yt-dlp JSON output rather than parsing human-readable tables.
- Do not treat playlists as part of the single-item flow.

### Format List

- Show format identifier, container, resolution, width, height, frame rate, video codec, audio codec, estimated size, and bitrate when available.
- Exclude audio-only entries, storyboard entries, and entries without a usable video codec or height.
- Keep selection stable after the list is populated.

### Download

- Download the selected video format.
- Add best audio only when the selected format has no audio stream.
- Use FFmpeg to merge streams when required.
- Let the user select a writable output directory.
- Display progress, speed, and ETA when yt-dlp supplies them.
- Let the user cancel an active query or download.
- Reveal the completed file in Explorer or Finder.

### Toolchain

- Verify yt-dlp, FFmpeg, ffprobe, and Deno before an operation that requires them.
- Do not rely on unverified downloads during release packaging.
- Keep tool versions and checksums in a release manifest rather than Git-tracking binaries.
- Show a useful error when a required tool is missing, incompatible, or cannot launch.

### Network and Authentication

- Support direct mode, system proxy mode, and a user-supplied custom proxy.
- Do not enable a localhost proxy by default for new users.
- Treat browser-exported cookies as optional private user data.
- Public content must not be blocked solely because no cookie file exists.
- Never print cookie contents or authorization headers to logs.

### Diagnostics

- Provide concise user-facing status and optional detailed logs.
- Preserve raw tool errors only in detailed logs.
- Map common authentication, network, JavaScript-runtime, FFmpeg, format, and URL errors to actionable messages.

## Non-Functional Requirements

- Native desktop UI on each supported platform.
- UI remains responsive while querying and downloading.
- Background work has explicit ownership and cancellation.
- UTF-8 output remains valid when a multibyte character crosses a pipe-read boundary.
- User-visible behavior and release version remain aligned across both platforms.
- No cookies, downloaded media, credentials, local paths, IDE state, or debug symbols in source control or public packages.

## Out of Scope

- Playlist and channel downloads.
- Concurrent download queues.
- Download history or media cataloguing.
- Application self-update.
- Browser-cookie extraction.
- DRM circumvention.
- Stable Intel Mac support.

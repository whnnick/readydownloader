# 0.1.1 Black-Box Functional Check

## Requirement coverage

| Product area | Status | Evidence |
| --- | --- | --- |
| Chinese main interface | Complete | Real app window, controls, and accessibility tree inspected |
| ReadyType visual alignment | Complete | Adaptive neutrals, moss accent, panels, and status hierarchy applied |
| URL validation | Complete | Scheme-less URL shows a Chinese error; complete HTTP/HTTPS URL enables query |
| Format query | Complete | Real app queried local DASH and displayed one 320x180 video format |
| Download modes | Complete | Best quality, compatible MP4, and selected-format switching and guidance passed |
| Download and audio merge | Complete | Local real yt-dlp download plus FFmpeg/FFprobe merge verification passed |
| Settings and privacy | Complete | Chinese settings, system-proxy default, optional cookies, and detailed logs off by default passed |
| Progress and cancellation | Partial | State model and cancel entry points passed; long-running UI cancellation still needs real-network acceptance |

## Automated evidence

- `swift test --package-path apps/macos`: 20 tests in 5 suites passed.
- `./script/test_macos_download_integration.sh`: real yt-dlp download, FFmpeg merge, and FFprobe stream checks passed.
- `./script/build_and_run.sh --verify`: app build, local APP staging, launch, and process check passed.

## Real-environment acceptance remaining

- Complete authorized public downloads from Instagram, YouTube, and other services.
- Cancellation and temporary-file behavior during a long public download.
- First launch under a clean macOS account.
- Developer ID signing, notarization, and Gatekeeper assessment.
- Remote GitHub CI and Release workflows.

## Release judgment

The local Chinese UI, format-query path, and download core pass. Do not claim full public-release acceptance until the real-environment items above are complete.

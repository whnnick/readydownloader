# 0.1.2 Black-Box Functional Check

| Product area | Status | Evidence |
| --- | --- | --- |
| Packaged tool resolution | Complete | Bundled tools take priority; release audit checks yt-dlp, Deno, FFmpeg, and FFprobe |
| Development fallback | Complete | Test passes for ancestor search of `tools/macos-arm64` when bundle resources are absent |
| Chinese interface | Complete | Real app main window, settings, format table, status, and commands inspected |
| English interface | Complete | Switching in Settings immediately updates the window, controls, format table, and status |
| State preservation | Complete | The local DASH result and downloadable state remain intact after switching languages |
| Recovery guidance | Complete | Missing-component guidance points to the current DMG/ZIP or development preparation flow in both languages |
| Download and audio merge | Complete | Real yt-dlp download, FFmpeg merge, and FFprobe stream checks pass |

## Automated evidence

- `swift test --package-path apps/macos`: 25 tests in 6 suites passed.
- `./script/test_macos_download_integration.sh`: real local download and merge passed.
- `./script/package_macos.sh`: 0.1.2 APP, ZIP, DMG, signing, checksums, and package audit passed.

## Real-environment acceptance remaining

- Complete authorized public downloads from Instagram and other services.
- Long-running public-download cancellation, clean macOS account, Developer ID notarization, and remote GitHub Release.

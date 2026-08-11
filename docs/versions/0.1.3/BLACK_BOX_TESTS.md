# 0.1.3 Black-Box Functional Check

| Product area | Status | Evidence |
| --- | --- | --- |
| Compatible-media detection | Complete | Tests accept H.264/AAC/yuv420p MP4 and reject VP9, non-AAC audio, and non-4:2:0 video |
| Best-quality behavior | Complete | Existing unrestricted selector is unchanged |
| iPhone-compatible conversion | Complete | Bundled FFmpeg converts incompatible video to H.264/yuv420p and available audio to AAC |
| Reported Instagram reel | Complete | The source was VP9/yuv420p MP4; the converted temporary result is H.264/yuv420p MP4. The source exposed no audio stream |
| Bilingual progress state | Complete | Chinese and English conversion-state tests pass; the real Chinese app shows the iPhone Compatible mode and explicit codec behavior |
| Toolchain contract | Complete | Tool verification requires both H.264 VideoToolbox and AAC encoders |
| Release package | Complete | 0.1.3 APP/ZIP/DMG, nested signing, checksums, DMG CRC, toolchain, and packaged H.264 conversion checks pass |

## Automated and real-process evidence

- `swift test --package-path apps/macos`: 30 tests in 7 suites passed before packaging.
- `./script/test_macos_download_integration.sh`: local DASH download, merge, H.264/AAC conversion, and FFprobe checks passed.
- `./script/package_macos.sh`: 0.1.3 APP, ZIP, DMG, signing, checksums, packaged VideoToolbox conversion, and package audit passed.
- The user-reported public Instagram URL was downloaded to a temporary directory and changed from VP9 to H.264 while retaining 720×1280 resolution.

## Real-environment acceptance remaining

- Share the new 0.1.3 result to a physical iPhone and confirm playback in the user's target app.
- Developer ID notarization and remote GitHub Release.

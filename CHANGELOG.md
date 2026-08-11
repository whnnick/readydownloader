# Changelog

All notable changes to this project will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.1.4] - Unreleased

### Changed

- Renamed the product, macOS app, Swift package, Windows solution, executable, and release artifacts to ReadyDownloader.
- Changed the macOS bundle identifier to `com.readydownloader.app`, matching the ReadySuite product naming convention.
- Established `readydownloader` as the GitHub repository slug and `/readydownloader` as the future ReadySuite website route.
- Lowered the primary Mac runtime target from macOS 14 to macOS 13 and the Swift Package tools version from Swift 6 to Swift 5.10.
- Replaced macOS 14-only Observation and empty-state dependencies with Combine and compatible SwiftUI implementations.
- Migrated all 30 tests from Swift Testing to XCTest so they run with the Swift 5.10 toolchain.

### Fixed

- Release verification now rejects packages with the wrong application name, executable, or bundle identifier.

### Verified

- Renamed Swift tests, build scripts, GitHub Actions release assets, bilingual documentation, and Windows project metadata together.
- Verified the executable's Mach-O minimum system version is macOS 13.0 and reran all 30 XCTest cases locally.
- Passed the GitHub macOS 14 / Swift 5.10 workflow, including repository checks and the real local download-and-merge integration path.

## [0.1.3] - Unreleased

### Changed

- Renamed the macOS compatible mode to iPhone Compatible and clarified that MP4 containers alone do not guarantee playback compatibility.
- Compatible downloads now inspect the finished file and preserve already-compatible H.264/AAC media without unnecessary transcoding.

### Fixed

- VP9, AV1, non-AAC audio, and non-4:2:0 video in MP4 downloads are now converted to H.264, AAC when audio is available, and yuv420p using Apple's VideoToolbox encoder.
- Compatible conversion keeps the downloaded filename and reports a dedicated bilingual conversion status before completion.

### Verified

- Added compatibility probe, VP9 regression, transcode-argument, and bilingual conversion-state tests.
- Verified the reported Instagram reel changed from VP9/yuv420p MP4 to H.264/yuv420p MP4; the source did not expose an audio stream.
- Extended toolchain and release checks to require and exercise H.264 VideoToolbox encoding.

## [0.1.2] - Unreleased

### Added

- Persistent, immediate Simplified Chinese and English switching for the main window, settings, commands, format table, status, and errors.

### Fixed

- Toolchain resolution now falls back from missing bundle resources to repository tools for SwiftPM development executables and stale local app copies.
- Missing-component guidance now distinguishes an incomplete app copy from a current packaged release.

### Verified

- Added toolchain fallback and bilingual state-preservation tests.
- Verified a real local DASH query in Chinese, switched to English with the parsed result still present, and confirmed all download controls and format columns updated.

## [0.1.1] - Development baseline

### Changed

- Reworked the macOS app into a Chinese, ReadyType-aligned single-task download workspace.
- Replaced the oversized empty table workflow with guided URL, download-settings, format, and status panels.
- Added inline URL validation, stale-result clearing, localized common-error guidance, and clearer loading, cancellation, success, and failure states.
- Localized the macOS settings window, commands, format table, file chooser, download modes, and tool errors.

### Verified

- Added coverage for URL validation, localized authentication guidance, and stale-state clearing.
- Verified the real app's invalid/valid URL states, mode switching, Chinese settings, and local DASH format query.
- Re-verified the real yt-dlp best-quality download and FFmpeg audio/video merge path.

### Added

- Open-source repository policies and bilingual project documentation.
- Cross-platform v0.1.0 requirements, architecture, plan, and release checks.
- Native SwiftUI macOS application foundation with a settings scene, toolchain resolution, cancellable yt-dlp format queries, and a format table.
- Swift format-parser tests and a project-local macOS build-and-run entry point.
- A shared sanitized yt-dlp JSON fixture for cross-platform parser conformance.
- Mac-first download workflow with unrestricted best quality, compatible MP4, and manual format modes.
- Real-time progress, cancellation, persistent destination bookmarks, and Finder reveal.
- Reliable destination restoration for non-sandboxed development and GitHub builds when a security-scoped bookmark cannot be resolved.
- An opt-in detailed-log setting that keeps raw yt-dlp output hidden by default.
- Local integration verification of separate DASH video/audio download and merge using the real yt-dlp process and bundled FFmpeg.
- Pinned macOS arm64 toolchain inputs with SHA-256 verification and an official-source FFmpeg build.
- Reproducible APP, ZIP, and DMG packaging with nested-code signing, optional notarization, package auditing, and checksums.
- macOS pull-request CI and a credential-gated, tag-driven GitHub Release workflow.
- Repository and release-package denylist scans for private data, credentials, media, and stale artifacts.
- Original cross-platform branding artwork and a reproducible macOS `.icns` generation pipeline.
- A versioned supported-site boundary based on the pinned yt-dlp extractor snapshot.

### Security

- Excluded cookies, downloaded media, tool binaries, IDE state, and build outputs from Git.

## [0.1.0] - Development baseline

- First planned public release with Windows x64 and macOS Apple Silicon support.

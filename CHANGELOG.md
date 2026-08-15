# Changelog

All notable changes to this project will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.2.1] - 2026-08-15

### Added

- Added the same Vercel Web Analytics integration used by ReadySuite, including page views and privacy-safe instrumentation for analysis, download, language, save-file, and GitHub interactions.
- Added Vercel Speed Insights instrumentation so performance collection can start when the team plan has capacity.
- Added automated analytics payload tests that restrict custom events to at most two fields: language plus download mode or aggregate format count.

### Verified

- Enabled Web Analytics on the production Vercel project.
- Passed 30 Web tests, TypeScript checks, and a Next.js production build.

### Known limitations

- The ReadySuite Hobby team currently permits Speed Insights on only one project. ReadyDownloader includes the integration code, but production collection cannot be enabled without moving the existing slot or upgrading the team.
- Vercel custom events require Pro or Enterprise. On the current Hobby plan, page views are collected but the instrumented product-funnel events are not available in the dashboard.

## [0.2.0] - 2026-08-15

### Added

- Added the production bilingual Web app at `https://readydownloader.vercel.app` with format inspection, Best Quality, iPhone Compatible, and Selected Format modes.
- Added private temporary Blob storage, 24-hour signed download URLs, scheduled cleanup, public-source allowlisting, SSRF protection, request limits, cancellation, and a 500 MB output cap.
- Added pinned and checksum-verified yt-dlp builds for Linux deployment and macOS development, plus static FFmpeg and FFprobe runtime tracing.
- Added Web unit tests, TypeScript checks, production builds, CI, and bilingual deployment and black-box documentation.

### Fixed

- Web iPhone-compatible downloads now inspect the final media and convert incompatible video/audio to MP4, H.264, AAC when available, and yuv420p.
- Language switching now updates active status text and the page title without discarding parsed formats.
- Fixed mobile horizontal overflow and local macOS development tool selection.

### Verified

- Parsed the reported Instagram Reel into eight formats through both local and production APIs.
- Completed the production download, conversion, private upload, and expiring signed-link flow; FFprobe confirmed MP4, H.264, AAC, and yuv420p output.
- Verified `readydownloader.vercel.app` on desktop and mobile with no browser console warnings or errors, then removed all smoke-test media.

## [0.1.4] - 2026-08-11

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
- Made Tag publication, GitHub Release assets, checksum validation, and the public latest-release check a mandatory synchronized release operation.

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

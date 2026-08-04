# Changelog

All notable changes to this project will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.1.1] - Unreleased

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

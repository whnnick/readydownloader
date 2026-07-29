# 0.1.0 Architecture

## Decision

Use native platform clients with a shared behavioral contract instead of introducing a cross-platform UI framework.

- Windows remains C++17 and Win32.
- macOS uses Swift 6 and SwiftUI.
- Shared artifacts are requirements, yt-dlp argument rules, JSON fixtures, tool manifests, release version, and black-box acceptance criteria.

macOS is the primary product and release platform. Windows is a compatibility implementation that follows the shared contract after Mac milestones are verified; Windows work does not block the Mac release train.

This keeps the current Windows investment while allowing the macOS app to use `Process`, `Pipe`, `JSONDecoder`, Swift Concurrency, Finder integration, and security-scoped file access directly.

## Repository Shape

The target structure is:

```text
apps/windows/       Windows application and tests
apps/macos/         Swift package, application, and tests
fixtures/yt-dlp/    Sanitized shared JSON fixtures
scripts/            Build, verification, and packaging entry points
docs/versions/      Versioned requirements and release evidence
.github/             CI, release workflows, and contribution templates
```

The Windows project may move into `apps/windows/` only after a verified build baseline exists. The migration must not be mixed with behavior changes.

## Shared Behavior Contract

Both platform adapters must implement equivalent operations:

```text
checkToolchain()
queryFormats(url, network, cookies)
download(url, selection, destination, network, cookies)
cancel(operation)
```

Both clients consume the same sanitized fixture expectations for filtering and presentation. Platform-specific code owns process launch, paths, UI state, file selection, and reveal-in-file-manager behavior.

## macOS Components

- `YouTubeDlpDownloaderApp`: `WindowGroup` entry point plus a `Settings` scene.
- `DownloadStore`: main-actor state for URL, formats, selection, progress, and errors.
- `YtDlpClient`: actor responsible for process lifetime and cancellation.
- `FormatParser`: decodes and filters yt-dlp JSON.
- `ToolchainResolver`: locates and validates bundled development or release tools.
- `DownloadDirectoryStore`: persists security-scoped bookmarks.

The app is distributed directly through GitHub Releases rather than the Mac App Store for v0.1.0. Debug builds do not require notarization. Stable distribution should sign nested executables first, sign the app with hardened runtime, notarize the archive, and staple the ticket.

## Windows Components

- Win32 UI owns controls and main-window messages.
- `YtDlpService` owns tool arguments, process execution, format parsing, and error mapping until those responsibilities are separated into focused modules.
- Worker operations must be joinable or cancellable; detached UI workers are not an accepted release architecture.

## Toolchain Distribution

Source control contains only a manifest. Packaging scripts download platform-specific artifacts, verify SHA-256 values, copy licenses, and then stage the release. A packaged application must never download unpinned tools as part of its build.

## Versioning

`VERSION` is the repository source of truth. Platform manifests, badges, changelogs, release tags, archive names, and release notes must match it before publishing.

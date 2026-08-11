# ReadyDownloader 0.1.0

Version 0.1.0 is the first planned public cross-platform release.

## Release Goal

Deliver a trustworthy native desktop interface around yt-dlp for:

- Windows 10+ on x64;
- macOS 14+ on Apple Silicon.

Both clients must implement the same core workflow: query a single media URL, inspect video formats, choose an output, download with visible progress, merge audio when required, and locate the completed file.

## Documents

- [Requirements](./REQUIREMENTS.md)
- [Architecture](./ARCHITECTURE.md)
- [Implementation plan](./PLAN.md)
- [Supported-site boundary](./SUPPORTED_SITES.md)
- [Black-box release checks](./BLACK_BOX_TESTS.md)
- [Release guide](../../RELEASE.md)
- [简体中文](./README.zh-CN.md)

## Release State

Status: macOS implementation and release preparation.

The macOS download MVP, local SwiftUI workflow acceptance, and reproducible local packaging are implemented, but an authorized public URL plus signed and notarized artifacts still require real-environment acceptance and Apple release credentials. The Windows code remains a compatibility prototype and does not block a Mac-only v0.1.0 release.

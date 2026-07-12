# YouTubeDlpDownloader 0.1.0

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
- [Black-box release checks](./BLACK_BOX_TESTS.md)
- [简体中文](./README.zh-CN.md)

## Release State

Status: planning and implementation.

The current Windows code is a prototype and is not yet a v0.1.0 release candidate. The macOS client has not yet reached MVP status.

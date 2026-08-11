# ReadyDownloader 0.1.2

Version `0.1.2` fixes missing runtime components in incomplete macOS builds and adds complete, immediate Simplified Chinese / English switching.

## Goals

- Switch the main window, settings, commands, format table, status, and errors between Chinese and English.
- Persist the language preference while preserving the current URL, parsed formats, and download state during a switch.
- Prefer bundled release tools while allowing SwiftPM development builds to fall back to the repository's pinned tool directory.
- Give a precise recovery path for missing tools instead of a generic reinstall instruction.

## Acceptance entry points

- [0.1.2 black-box functional check](./BLACK_BOX_TESTS.md)
- [0.1.1 Chinese UI baseline](../0.1.1/README.md)
- [0.1.0 supported-site boundary](../0.1.0/SUPPORTED_SITES.md)
- [Release process](../../RELEASE.md)

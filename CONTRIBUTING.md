# Contributing

Thank you for helping improve ReadyDownloader.

## Before You Start

- Read the current version requirements and implementation plan under `docs/versions/`.
- Keep Windows and macOS user-visible behavior aligned with the shared requirements.
- Do not add unrelated refactors or generated binaries to a feature change.
- Never commit cookies, tokens, downloaded media, tool binaries, private paths, or account information.

## Development Workflow

1. Create a focused branch from `main`.
2. Make the smallest coherent change that satisfies the requirement.
3. Add or update tests and black-box verification evidence.
4. Update both English and Chinese user-facing documentation when behavior changes.
5. Update `VERSION`, `CHANGELOG.md`, and `CHANGELOG.zh-CN.md` for a user-visible release change.
6. Run the platform-specific verification commands and the sensitive-information scan.
7. Submit a pull request describing behavior, verification evidence, and remaining real-environment checks.

## Commit Style

Prefer small commits with a clear scope, for example:

```text
feat(macos): add format query service
fix(windows): honor selected download directory
test: add yt-dlp format fixtures
docs: define v0.1.0 release criteria
ci: add cross-platform release packaging
```

## Legal and Responsible Use

Contributions must not add DRM circumvention, credential extraction, stealth account access, or features intended to download content without authorization.

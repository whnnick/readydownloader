# 0.1.0 Black-Box Functional Check

Status: not yet a release candidate.

## Requirement Mapping

| Product area | Windows | macOS | Required evidence |
| --- | --- | --- | --- |
| Launch and toolchain check | Pending | Local ZIP/DMG build, audit, and ZIP launch pass; clean-machine pending | Clean launch and actionable missing-tool errors |
| URL validation | Pending | Implemented | Empty URL rejected without a process launch |
| Format query and filtering | Pending | Shared fixture and local App UI pass; public real URL pending | Sanitized fixture tests and one authorized real URL |
| Format selection | Pending | Selector tests pass | Selection remains visible and downloads the requested video stream |
| Audio merge | Pending | Local real yt-dlp separate-stream download, App UI, and bundled FFmpeg merge pass; public real URL pending | Video-only selection produces a playable merged file |
| Output directory | Pending | Local App UI selection/output and restart fallback tests pass; normal user folder pending | File appears in the user-selected directory |
| Progress and cancellation | Pending | Parser and local integration pass; UI acceptance pending | Responsive UI, changing progress, and terminated child process |
| Network modes | Pending | Implemented; real-network matrix pending | Direct, system, and custom-proxy argument verification |
| Optional cookies | Pending | Implemented; authenticated check pending | Public URL works without cookies; private test data is never logged |
| Diagnostics | Pending | Raw output is opt-in and tested; friendly common-error mapping remains partial | Friendly common errors plus opt-in detailed tool output |

## Automated Verification Required

- Windows Release build.
- macOS Swift tests and release build.
- App icon generation, bundle resource, and Info.plist reference.
- Shared sanitized format-fixture expectations.
- Local real yt-dlp best-quality download and separate-stream merge.
- Local SwiftUI query, download completion, temporary output selection, and Finder reveal.
- Sensitive-information scan over tracked files and Git history.
- Release-package denylist scan.
- Version consistency check across `VERSION`, applications, changelogs, tags, and archive names.

## Real-Environment Verification Required

- Authorized public video download on both platforms.
- Authorized video-only plus audio merge on both platforms.
- Cancel a partially downloaded file on both platforms.
- Finder and Explorer reveal behavior.
- Direct and system-proxy behavior on normal user machines.
- First launch on a clean Windows account and a clean macOS account.
- Gatekeeper assessment of the signed and notarized macOS artifact.

## Release Package Denylist

The release must not contain:

- cookie files;
- downloaded media or `.part` files;
- `.env` files or credentials;
- PDB, OBJ, IPCH, TLOG, or IDE databases;
- absolute developer paths;
- `.codex`, `.agents`, `AGENTS.md`, or internal-only checklists;
- stale artifacts from another version.

## Current Release Blockers

1. A real authorized public video and a video-only audio merge still need UI acceptance on macOS.
2. The new toolchain and package flow still needs clean-machine verification.
3. The macOS CI and release workflows have not run on a remote GitHub repository.
4. macOS signing and notarization credentials have not been validated.
5. GitHub public surfaces and final release assets do not yet exist.
6. Windows compatibility work remains incomplete but does not block the Mac-first release unless the release is advertised as dual-platform.

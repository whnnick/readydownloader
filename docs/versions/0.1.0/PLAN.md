# 0.1.0 Implementation Plan

## Milestone 0: Open-Source Baseline

- Ignore private data, downloaded media, tool binaries, build outputs, and IDE state.
- Add license, security, contribution, conduct, changelog, and third-party notices.
- Initialize a clean local Git history only after verifying ignored files.

Exit criteria: tracked-file inventory and sensitive-information scan pass.

## Milestone 1: Version Contract

- Publish bilingual requirements, architecture, plan, and black-box checks.
- Establish `VERSION` as the single release version source.
- Define Windows and macOS feature parity for v0.1.0.

Exit criteria: all README links resolve and English/Chinese release scope agrees.

## Milestone 2: macOS MVP

- Create a multi-file SwiftPM SwiftUI application.
- Implement toolchain validation, JSON format query, unrestricted best-quality download, compatible MP4, manual selection, progress, cancellation, destination selection, and Finder reveal.
- Add settings for network mode, custom proxy, optional cookies, and detailed logs.
- Add `script/build_and_run.sh` and the Codex Run action.
- Add Swift tests using shared sanitized fixtures.

Exit criteria: `swift test` and the local app launch verification pass; an authorized real URL can complete a download and merge.

Implementation status: the shared fixture tests and a fully local real yt-dlp
separate-stream download/merge test are implemented. Authorized public-URL and
UI acceptance remain pending.

## Milestone 3: macOS Toolchain and Packaging

- Add pinned manifests for macOS arm64 tools.
- Download and verify artifacts during packaging.
- Copy all required third-party licenses.
- Build macOS APP ZIP and DMG.
- Verify that each package contains only current-version artifacts.

Exit criteria: clean-machine package checks pass without relying on a developer's PATH.

Implementation status: scripts, pinned inputs, official-source FFmpeg build,
license collection, APP/ZIP/DMG generation, checksums, and package auditing are
implemented. Clean-machine validation is still required.

## Milestone 4: macOS GitHub Release

- Add macOS CI for pushes and pull requests.
- Add tag-driven release workflow.
- Add secret and package-content scans.
- Generate `SHA256SUMS.txt`.
- Sign and notarize macOS stable releases when credentials are configured.
- Publish assets and verify repository About, remote `main`, Release assets, latest release, and download links separately.

Exit criteria: the macOS v0.1.0 black-box report has no release blockers and the public GitHub surfaces are verified.

Implementation status: pull-request CI and a credential-gated tag workflow are
implemented locally. Developer ID credentials, notarization, remote workflow
execution, and public-surface verification remain pending.

## Milestone 5: Windows Compatibility

- Establish a reproducible Windows Release build in CI.
- Make selected tool and output paths truthful or remove misleading controls.
- Make cookies optional and align best-quality selectors with macOS.
- Add audio only for video-only selections.
- Remove obsolete JSON, text-table, and process-execution paths.
- Replace detached workers with owned, cancellable operations.
- Preserve UTF-8 correctly across pipe-read boundaries.

Exit criteria: Windows follows the shared behavior contract without blocking the Mac release train.

## Commit Boundaries

Keep security baseline, documentation, macOS behavior, tests, release automation, and Windows compatibility work in separate verified commits.

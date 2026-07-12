# 0.1.0 Black-Box Functional Check

Status: not yet a release candidate.

## Requirement Mapping

| Product area | Windows | macOS | Required evidence |
| --- | --- | --- | --- |
| Launch and toolchain check | Pending | Pending | Clean launch and actionable missing-tool errors |
| URL validation | Pending | Pending | Empty URL rejected without a process launch |
| Format query and filtering | Pending | Pending | Sanitized fixture tests and one authorized real URL |
| Format selection | Pending | Pending | Selection remains visible and downloads the requested video stream |
| Audio merge | Pending | Pending | Video-only selection produces a playable merged file |
| Output directory | Pending | Pending | File appears in the user-selected directory |
| Progress and cancellation | Pending | Pending | Responsive UI, changing progress, and terminated child process |
| Network modes | Pending | Pending | Direct, system, and custom-proxy argument verification |
| Optional cookies | Pending | Pending | Public URL works without cookies; private test data is never logged |
| Diagnostics | Pending | Pending | Friendly common errors plus opt-in detailed tool output |

## Automated Verification Required

- Windows Release build.
- macOS Swift tests and release build.
- Shared sanitized format-fixture expectations.
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

1. Windows stabilization is incomplete.
2. macOS MVP is not implemented.
3. Shared fixture tests are not implemented.
4. Tool manifests and checksums are not defined.
5. CI and release packaging are not implemented.
6. macOS signing and notarization credentials have not been validated.
7. GitHub public surfaces and final release assets do not yet exist.

# 0.2.0 Black-Box Functional Check

Date: 2026-08-15

| Requirement | Status | Evidence |
| --- | --- | --- |
| Production Web app | Complete | `https://readydownloader.vercel.app` returns HTTP 200 and the Vercel deployment is READY |
| Chinese/English UI | Complete | Fresh browser session verified both languages, active-status translation, and localized page title |
| Desktop/mobile layout | Complete | Playwright verified 1440×1000 and 390×844 production viewports |
| Browser quality workflow | Complete | URL validation, three modes, format table, cancellation, progress, and signed result action are present |
| Instagram analysis | Complete | The reported public Reel returned eight formats locally and in production |
| iPhone compatibility | Complete | Production flow emitted download, conversion, upload, and done stages; FFprobe confirmed MP4, H.264, AAC, and yuv420p |
| Temporary storage | Complete | Output used a private Blob and an expiring signed URL; smoke-test Blobs were deleted after verification |
| Network safety | Complete | Local/private URLs are blocked; only approved public source domains are accepted |
| Automated checks | Complete | 27 Vitest tests, TypeScript check, and Next.js production build pass locally |
| macOS regression and package | Complete | 30 XCTest cases pass; 0.2.0 APP/ZIP/DMG, signing, checksums, DMG CRC, toolchain, merge, and compatibility conversion checks pass |
| Browser console | Complete | Production desktop/mobile session reported zero errors and zero warnings |

## Known Boundaries

- Web requests do not accept cookies and cannot access private, login-only, or DRM-protected media.
- The browser controls the final local download directory.
- A 500 MB output cap, one-video/no-playlist rule, best-effort rate limits, and 24-hour retention apply.
- Site availability remains URL-, region-, and extractor-dependent.
- macOS public artifacts remain ad-hoc signed and not Apple-notarized unless release credentials are configured.

## Release Gate

Source `main`, `v0.2.0`, the matching GitHub Release, its three macOS assets, checksums, GitHub latest, and the Vercel production URL must all be publicly verified before this version is declared fully released.

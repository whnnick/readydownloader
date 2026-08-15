# 0.2.1 Black-Box Functional Check

Date: 2026-08-15

| Requirement | Status | Evidence |
| --- | --- | --- |
| ReadySuite-aligned analytics | Complete | Vercel Web Analytics enabled; production script, page-view, and custom-event requests returned HTTP 200 |
| Privacy-safe custom events | Complete in source | Typed two-field allowlist and payload tests exclude media input, tokens, filenames, signed URLs, and raw errors; dashboard collection requires Pro or Enterprise |
| Speed Insights | Partial | Integration is present; Hobby team project-slot limit blocks production enablement |
| Automated checks | Complete | 30 Vitest tests, TypeScript check, and Next.js production build pass locally |
| Release synchronization | In progress | Production is deployed; source push, tag, Release assets, checksums, and latest verification remain pending |
| Browser console | Complete | Production analytics browser session reported zero errors and zero warnings |

## Known Boundary

Vercel Speed Insights cannot be enabled on a second project under the current Hobby team. Existing ReadySuite monitoring was left unchanged.

Vercel Web Analytics page views remain available on Hobby, while custom events require Pro or Enterprise.

## Production Evidence

Deployment `dpl_3ubhPXJ8egbvmCdRBSwXfMrorZKC` reached READY and was aliased to `https://readydownloader.vercel.app`. A browser session that allowed normal visitor collection received HTTP 200 for the first-party analytics script and `/view` endpoint. Switching to English emitted `language_change` to the `/event` endpoint with only `{ "language": "en" }`, also returning HTTP 200.

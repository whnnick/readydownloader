# 0.2.1 Black-Box Functional Check

Date: 2026-08-15

| Requirement | Status | Evidence |
| --- | --- | --- |
| ReadySuite-aligned analytics | In progress | Vercel Web Analytics enabled; production deployment and browser request verification pending |
| Privacy-safe custom events | Complete in source | Typed two-field allowlist and payload tests exclude media input, tokens, filenames, signed URLs, and raw errors; dashboard collection requires Pro or Enterprise |
| Speed Insights | Partial | Integration is present; Hobby team project-slot limit blocks production enablement |
| Automated checks | Complete | 30 Vitest tests, TypeScript check, and Next.js production build pass locally |
| Release synchronization | In progress | Source push, tag, Release assets, checksums, latest, and production deployment pending |

## Known Boundary

Vercel Speed Insights cannot be enabled on a second project under the current Hobby team. Existing ReadySuite monitoring was left unchanged.

Vercel Web Analytics page views remain available on Hobby, while custom events require Pro or Enterprise.

# Analytics and Privacy Boundary

ReadyDownloader Web uses Vercel Web Analytics, matching the ReadySuite website. Automatic page views and these custom events are collected:

| Event | Allowed custom fields |
| --- | --- |
| `analyze_click`, `analyze_error` | language |
| `analyze_complete` | language, aggregate format count |
| `download_click`, `download_complete`, `download_error` | language, download mode |
| `file_save_click` | language, download mode |
| `github_click`, `language_change` | language |

Media URLs, page titles, output filenames, access tokens, signed Blob URLs, format identifiers, and raw errors are never added to custom event properties. Analytics must remain non-blocking and must not change download behavior.

Speed Insights is mounted in the application layout. The current Hobby team allows it on only one project, so production collection remains disabled for ReadyDownloader until the existing slot is moved or the team plan is upgraded.

Web Analytics page views are available on the current Hobby plan. Vercel custom events require Pro or Enterprise, so the product-funnel instrumentation will become visible only after a plan upgrade.

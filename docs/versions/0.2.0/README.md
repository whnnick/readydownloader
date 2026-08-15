# ReadyDownloader 0.2.0

Version `0.2.0` adds a production Web application while keeping macOS as the primary native product line.

## Delivered

- Production URL: [readydownloader.vercel.app](https://readydownloader.vercel.app/)
- Simplified Chinese and English UI with ReadyType-aligned styling
- Public-media analysis and a selectable format table
- Best Quality, iPhone Compatible, and Selected Format modes
- Server-side yt-dlp, FFmpeg merge, and H.264/AAC/yuv420p compatibility conversion
- Private Blob output with expiring signed links and scheduled deletion
- Source allowlisting, SSRF protection, rate limits, cancellation, and a 500 MB output cap
- Linux and macOS yt-dlp assets pinned to `2026.07.04` and verified by SHA-256

## Platform Boundaries

The Web app aligns the clients' core public-media workflow. It intentionally does not accept cookies, private/login media, custom proxies, arbitrary local download directories, playlists, or DRM-protected content. Source-site changes, region restrictions, and bot protection can still make an individual URL unavailable.

## Documentation

- [Black-box functional check](./BLACK_BOX_TESTS.md)
- [Web deployment guide](./WEB_DEPLOYMENT.md)
- [Release guide](../../RELEASE.md)

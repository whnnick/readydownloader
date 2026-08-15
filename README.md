<p align="center">
  English | <a href="./README.zh-CN.md">简体中文</a>
</p>

<p align="center">
  <img src="./assets/branding/AppIcon.png" width="128" alt="ReadyDownloader app icon">
</p>

<h1 align="center">ReadyDownloader</h1>

<p align="center">
  A ReadySuite video downloader for the Web, macOS, and Windows.
</p>

<p align="center">
  <img alt="Platforms" src="https://img.shields.io/badge/platform-Web%20%7C%20macOS%20%7C%20Windows-blue">
  <img alt="Version" src="https://img.shields.io/badge/version-0.2.1-green">
  <img alt="License" src="https://img.shields.io/badge/license-MIT-lightgrey">
  <a href="https://github.com/whnnick/readydownloader/actions/workflows/macos-ci.yml"><img alt="macOS CI" src="https://github.com/whnnick/readydownloader/actions/workflows/macos-ci.yml/badge.svg"></a>
</p>

<p align="center">
  <a href="https://github.com/whnnick/readydownloader">Source</a> ·
  <a href="https://readydownloader.vercel.app/">Web App</a> ·
  <a href="https://github.com/whnnick/readydownloader/releases/latest">Latest Release</a> ·
  <a href="https://github.com/whnnick/readydownloader/issues">Issues</a> ·
  <a href="https://readysuite.vercel.app/">ReadySuite</a>
</p>

> [!IMPORTANT]
> macOS is the primary product line. The Windows client remains available as a compatibility implementation and will follow the shared behavior contract without blocking Mac releases.

## Quick Start

Open [readydownloader.vercel.app](https://readydownloader.vercel.app/) to use the bilingual Web app without installation. Paste a supported public media URL, inspect formats, then choose Best Quality, iPhone Compatible, or a specific format.

Download the current macOS package from [GitHub Releases](https://github.com/whnnick/readydownloader/releases/latest), move `ReadyDownloader.app` to Applications, and open it. The current public package target is Apple Silicon on macOS 13 or later.

The current package is ad-hoc signed and not Apple-notarized. If macOS blocks
the first launch, Control-click the app in Finder, choose **Open**, and confirm
once. Do not disable Gatekeeper globally.

## What It Does

- Queries video metadata and available formats through yt-dlp JSON output.
- Shows resolution, frame rate, codecs, estimated size, and bitrate.
- Downloads the highest available quality by default, with an iPhone-compatible mode and manual-format alternatives.
- Inspects iPhone-compatible downloads and converts incompatible VP9/AV1 video to H.264, available audio to AAC, and pixel layout to yuv420p.
- Merges the best audio with FFmpeg when the chosen video stream has no audio.
- Supports direct, system-proxy, and custom-proxy network modes.
- Supports optional Netscape-format cookie import for content that requires an authenticated session.
- Reports download progress and actionable errors.

## Platform Status

| Platform | Technology | Status |
| --- | --- | --- |
| Web | Next.js 16, Vercel Functions, private Vercel Blob | Production at `readydownloader.vercel.app`; public-media core workflow implemented |
| macOS 13+ Apple Silicon | Swift 5.10+ and SwiftUI | Primary platform; download MVP and reproducible packaging implemented |
| Windows x64 | C++17 and Win32 | Compatibility platform; prototype available |

The Web app aligns the client’s format inspection and three download modes. Browser and service security intentionally exclude Cookie import, private/login media, custom proxies, arbitrary local folders, and DRM-protected content. Downloads are capped at 500 MB, stored privately, exposed through an expiring signed URL, and scheduled for deletion after 24 hours.

The production Web app uses the same Vercel Web Analytics integration as ReadySuite. Instrumented events contain only coarse product context and never include media URLs, titles, filenames, access tokens, signed download URLs, or raw errors. Custom-event dashboards require a supported Vercel plan; see the [analytics and privacy boundary](./docs/versions/0.2.1/ANALYTICS.md).

See the [v0.1.0 overview](./docs/versions/0.1.0/README.md), [requirements](./docs/versions/0.1.0/REQUIREMENTS.md), and [implementation plan](./docs/versions/0.1.0/PLAN.md).

The bundled yt-dlp build contains extractors for major services such as
YouTube, Bilibili, TikTok, Instagram, Facebook, X/Twitter, Vimeo, Twitch,
Reddit, AcFun, Douyu, Huya, iQIYI, Youku, and Weibo. Availability is
URL-specific and is not guaranteed; see the
[supported-site boundary](./docs/versions/0.1.0/SUPPORTED_SITES.md).

## Build the Current Windows Prototype

Requirements:

- Windows 10 or later
- Visual Studio 2022 with the Desktop development with C++ workload
- Windows 10 SDK

Open `ReadyDownloader.sln`, select `Release | x64`, and build the solution.

The current runtime expects this local layout:

```text
ReadyDownloader.exe
tools/
├── yt-dlp.exe
├── deno.exe
└── ffmpeg/bin/
    ├── ffmpeg.exe
    └── ffprobe.exe
config/
└── yt_cookies.txt       # optional private user data; never commit it
Downloads/
```

Tool binaries, cookies, downloads, and build outputs are deliberately excluded from Git.

## Build the macOS App

Run tests:

```bash
swift test --package-path apps/macos --disable-sandbox
```

Build and launch the `.app` bundle:

```bash
./script/build_and_run.sh
```

The Mac app provides a Chinese/English switchable, ReadyType-aligned workflow for format queries, unrestricted best-quality download, verified iPhone-compatible H.264 MP4 output, manual format selection, real-time progress, cancellation, persistent destination selection, Finder reveal, and opt-in detailed yt-dlp logs. Pinned Apple Silicon tools and local APP/ZIP/DMG packaging are available; signed and notarized public artifacts still require Apple release credentials.

## Build the Web App

```bash
cd apps/web
npm ci
npm test
npm run check
npm run build
npm run dev
```

See the [Web deployment guide](./docs/versions/0.2.0/WEB_DEPLOYMENT.md) for Vercel Blob, environment, retention, and production verification requirements.

## ReadySuite Integration

The canonical product key is `readydownloader`, the production Web app is `https://readydownloader.vercel.app`, and the planned ReadySuite catalog route is `/readydownloader`. Desktop downloads should point to `https://github.com/whnnick/readydownloader/releases/latest`. ReadySuite remains a separate website repository and release process.

## Documentation

- [v0.2.1 release overview](./docs/versions/0.2.1/README.md)
- [v0.2.1 black-box functional check](./docs/versions/0.2.1/BLACK_BOX_TESTS.md)
- [Analytics and privacy boundary](./docs/versions/0.2.1/ANALYTICS.md)
- [Web deployment guide](./docs/versions/0.2.0/WEB_DEPLOYMENT.md)
- [Requirements](./docs/versions/0.1.0/REQUIREMENTS.md)
- [Architecture](./docs/versions/0.1.0/ARCHITECTURE.md)
- [Implementation plan](./docs/versions/0.1.0/PLAN.md)
- [Supported-site boundary](./docs/versions/0.1.0/SUPPORTED_SITES.md)
- [Black-box release checks](./docs/versions/0.1.0/BLACK_BOX_TESTS.md)
- [Release guide](./docs/RELEASE.md)
- [Contributing](./CONTRIBUTING.md)
- [Security policy](./SECURITY.md)
- [Third-party notices](./THIRD_PARTY_NOTICES.md)

## Responsible Use

Use this software only for content you own or are authorized to download. You are responsible for complying with applicable law, website terms, copyright, and privacy requirements. This project does not provide DRM-circumvention functionality.

Never attach cookies, account tokens, private URLs, or downloaded private media to a GitHub issue.

## License

Released under the [MIT License](./LICENSE).

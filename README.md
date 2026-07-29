<p align="center">
  English | <a href="./README.zh-CN.md">简体中文</a>
</p>

<p align="center">
  <img src="./assets/branding/AppIcon.png" width="128" alt="YouTubeDlpDownloader app icon">
</p>

<h1 align="center">YouTubeDlpDownloader</h1>

<p align="center">
  A native Windows and macOS desktop interface for downloading media with yt-dlp.
</p>

<p align="center">
  <img alt="Platforms" src="https://img.shields.io/badge/platform-Windows%20%7C%20macOS-blue">
  <img alt="Version" src="https://img.shields.io/badge/version-0.1.0-green">
  <img alt="License" src="https://img.shields.io/badge/license-MIT-lightgrey">
</p>

> [!IMPORTANT]
> macOS is the primary product line. The Windows client remains available as a compatibility implementation and will follow the shared behavior contract without blocking Mac releases.

## What It Does

- Queries video metadata and available formats through yt-dlp JSON output.
- Shows resolution, frame rate, codecs, estimated size, and bitrate.
- Downloads the highest available quality by default, with compatible MP4 and manual-format alternatives.
- Merges the best audio with FFmpeg when the chosen video stream has no audio.
- Supports direct, system-proxy, and custom-proxy network modes.
- Supports optional Netscape-format cookie import for content that requires an authenticated session.
- Reports download progress and actionable errors.

## Platform Status

| Platform | Technology | Status |
| --- | --- | --- |
| macOS 14+ Apple Silicon | Swift 6 and SwiftUI | Primary platform; download MVP and reproducible packaging implemented |
| Windows x64 | C++17 and Win32 | Compatibility platform; prototype available |

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

Open `YouTubeDlpDownloader.sln`, select `Release | x64`, and build the solution.

The current runtime expects this local layout:

```text
YouTubeDlpDownloader.exe
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

The Mac app implements format queries, unrestricted best-quality download, compatible MP4 mode, manual format selection, real-time progress, cancellation, persistent destination selection, Finder reveal, and opt-in detailed yt-dlp logs. Pinned Apple Silicon tools and local APP/ZIP/DMG packaging are available; signed and notarized public artifacts still require Apple release credentials.

## Documentation

- [v0.1.0 release overview](./docs/versions/0.1.0/README.md)
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

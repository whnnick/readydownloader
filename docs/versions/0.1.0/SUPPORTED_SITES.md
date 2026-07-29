# 0.1.0 Supported-Site Boundary

## Snapshot

The macOS package pins [yt-dlp 2026.07.04](https://github.com/yt-dlp/yt-dlp/releases/tag/2026.07.04).
That bundled executable reports 1,752 extractor identifiers. This is not the
same as 1,752 guaranteed-working websites: one service may have several
extractors, and websites regularly change.

The [upstream supported-sites list](https://github.com/yt-dlp/yt-dlp/blob/master/supportedsites.md)
also states that an entry is not a guarantee and that the only reliable test is
to try the exact URL. Embedded players and direct media may additionally work
through yt-dlp's generic extractor.

## Representative Extractors Present

| Area | Examples detected in the bundled build | Current app boundary |
| --- | --- | --- |
| Major video and social services | YouTube, Bilibili, TikTok, Instagram, Facebook, X/Twitter, Reddit | One direct media URL at a time; login or restricted content may require an exported cookie file |
| Video hosting | Vimeo, Dailymotion, Rumble, VK | Public, non-DRM media when the service extractor still works |
| Chinese services | AcFun, Douyu, Huya, iQIYI, Youku, Weibo | Public or authorized non-DRM media; VIP, region, and login restrictions still apply |
| Live and VOD services | Twitch, Douyu, Huya, Niconico | Extractors are present, but long-running live-download acceptance is still pending |
| Broadcasters and publishers | BBC, CNN, ABC-family services, and many regional broadcasters | Availability varies by country, account, and stream protection |
| Audio and podcasts | SoundCloud, Bandcamp, Mixcloud, Apple Podcasts | Extractors are present, but v0.1.0 is video-first and does not yet claim audio-only UI support |
| Embedded or direct streams | Generic embedded video, HLS, and DASH URLs | Works when yt-dlp can discover an unprotected media stream |

The locally generated DASH test completes the full macOS query, best-quality
download, audio merge, output selection, and Finder reveal flow. On 2026-07-30,
the public test-video URL currently shown in the yt-dlp FAQ returned
`Video unavailable`, so it was not counted as public-platform acceptance.

## Not Guaranteed or Out of Scope

- DRM circumvention;
- deleted, private, paid, age-restricted, or region-blocked content without the
  user's valid access;
- a platform continuing to work after it changes its website or API;
- playlists, channels, queues, or batch downloads—the app passes
  `--no-playlist`;
- browser-cookie extraction, OAuth login, CAPTCHA solving, or external token
  providers;
- live-stream recording reliability in v0.1.0;
- audio-only format browsing in the current video-focused format table.

Some YouTube formats may require cookies or a PO Token as upstream restrictions
change. The app bundles Deno and FFmpeg for JavaScript extraction and
best-quality audio/video merging, but it does not generate PO Tokens or bypass
service access controls. See the official
[yt-dlp extractor notes](https://github.com/yt-dlp/yt-dlp/wiki/Extractors) and
[FAQ](https://github.com/yt-dlp/yt-dlp/wiki/FAQ).

Use the app only for media you own or are authorized to download.

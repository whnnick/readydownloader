# Third-Party Notices

YouTubeDlpDownloader invokes external tools that are maintained and licensed independently:

- yt-dlp
- FFmpeg and ffprobe
- Deno

These binaries are not stored in the source repository. Release tooling pins approved versions, verifies downloaded inputs, and includes the corresponding upstream license notices in each distribution package.

The presence of an external tool in a release package does not change the MIT license that applies to this project's own source code. Each external component remains subject to its upstream license.

The macOS arm64 release manifest records for every bundled component:

- exact version;
- upstream project URL;
- artifact URL;
- target platform and architecture;
- SHA-256 checksum;
- bundled license file.

The current macOS manifest pins:

- yt-dlp 2026.07.04, using the official standalone macOS executable;
- Deno 2.9.4, using the official Apple Silicon executable;
- FFmpeg and ffprobe 8.1.2, built from official source without enabling GPL or
  non-free external libraries.

The yt-dlp standalone executable contains third-party GPLv3+ components. The
distribution includes yt-dlp's generated `THIRD_PARTY_LICENSES.txt`, and the
license terms listed there continue to apply to that component.

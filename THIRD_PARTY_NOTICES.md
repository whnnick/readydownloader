# Third-Party Notices

YouTubeDlpDownloader invokes external tools that are maintained and licensed independently:

- yt-dlp
- FFmpeg and ffprobe
- Deno

These binaries are not stored in the source repository. Release tooling will pin approved versions, verify downloaded artifacts, and include the corresponding upstream license notices in each distribution package.

The presence of an external tool in a release package does not change the MIT license that applies to this project's own source code. Each external component remains subject to its upstream license.

Before the first public release, the release manifest must record for every bundled component:

- exact version;
- upstream project URL;
- artifact URL;
- target platform and architecture;
- SHA-256 checksum;
- bundled license file.

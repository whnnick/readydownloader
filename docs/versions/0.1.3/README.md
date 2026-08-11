# YouTubeDlpDownloader 0.1.3

Version `0.1.3` makes the macOS iPhone Compatible mode enforce a media-codec contract instead of relying on the `.mp4` filename alone.

## Goals

- Keep Best Quality unchanged and unrestricted.
- Prefer existing H.264/AAC sources, then inspect the finished file with FFprobe.
- Convert incompatible video to H.264/yuv420p and available audio to AAC with Apple's VideoToolbox encoder.
- Preserve the downloaded filename and show a bilingual conversion state while processing.
- Require the packaged FFmpeg toolchain to expose and exercise the H.264 VideoToolbox encoder.

## Acceptance entry points

- [0.1.3 black-box functional check](./BLACK_BOX_TESTS.md)
- [0.1.2 bilingual UI baseline](../0.1.2/README.md)
- [Release process](../../RELEASE.md)

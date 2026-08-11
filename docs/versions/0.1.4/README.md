# ReadyDownloader 0.1.4

Version `0.1.4` completes the product rename from the inherited project name to ReadyDownloader and establishes stable GitHub and ReadySuite integration identifiers.

It also broadens the primary Mac target to Apple Silicon Macs running macOS 13 or later and keeps the package buildable with Swift 5.10 and newer toolchains.

## Naming contract

- Product and application name: `ReadyDownloader`
- GitHub repository: `whnnick/readydownloader`
- macOS bundle identifier: `com.readydownloader.app`
- macOS and Windows executable name: `ReadyDownloader`
- Release artifact prefix: `ReadyDownloader-<version>-macos-arm64`
- Future ReadySuite product key and route: `readydownloader`, `/readydownloader`
- Future ReadySuite download target: `https://github.com/whnnick/readydownloader/releases/latest`

## Compatibility contract

- Minimum runtime: macOS 13.0
- Package tools version: Swift 5.10
- State model: Combine `ObservableObject`, without a macOS 14 Observation dependency
- Test harness: XCTest, available in the Swift 5.10 toolchain

## Acceptance entry points

- [0.1.4 black-box functional check](./BLACK_BOX_TESTS.md)
- [0.1.3 iPhone-compatible media baseline](../0.1.3/README.md)
- [Release process](../../RELEASE.md)

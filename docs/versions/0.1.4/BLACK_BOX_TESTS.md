# 0.1.4 Black-Box Functional Check

| Product area | Status | Evidence |
| --- | --- | --- |
| macOS product name | Complete | The real app window, menu-bar app name, process, bundle, and executable are ReadyDownloader |
| macOS bundle identity | Complete | Built and packaged apps report `CFBundleIdentifier` as `com.readydownloader.app` |
| Swift package and tests | Complete | ReadyDownloader and ReadyDownloaderTests build; 30 tests in 7 suites pass |
| macOS runtime compatibility | Partial | SwiftPM and the Mach-O executable target macOS 13.0; a real macOS 13 launch remains to be checked |
| Swift toolchain compatibility | Complete | GitHub's macOS 14 / Swift 5.10 runner builds the package and passes all 30 XCTest cases |
| Windows project metadata | Partial | Solution, project, namespace, target, window class, and executable names are updated; a Windows build still requires Windows |
| GitHub Actions | Complete | CI run 31471323256 and Release run 31471639759 both pass |
| ReadySuite handoff | Complete | Product key, route, repository, latest-release URL, and platform summary are documented |
| Release package | Complete | ReadyDownloader 0.1.4 APP/ZIP/DMG, nested signing, checksums, DMG CRC, toolchain, and compatibility conversion checks pass |
| Repository release hygiene | Complete | Version consistency, shell syntax, sensitive-information scan, legacy-name search, and Git diff checks pass |
| GitHub remote | Complete | Public repository `whnnick/readydownloader` exists, `main` is the default tracked branch, and the local history has been pushed |
| GitHub Release | Complete | Public `v0.1.4` is latest, non-draft, non-prerelease, and contains the DMG, ZIP, and checksum file |

## Verification evidence

- `swift test --package-path apps/macos`: 30 tests in 7 suites passed.
- `vtool -show-build ReadyDownloader`: the executable reports `minos 13.0`.
- `./script/build_and_run.sh --verify`: the ReadyDownloader process launched successfully.
- Real UI inspection confirmed the ReadyDownloader window title, header, application menu, and Chinese workflow.
- `./script/package_macos.sh`: ReadyDownloader 0.1.4 signing, ZIP/DMG, checksums, package audit, and H.264 compatibility conversion passed.
- [GitHub Actions run 31465042120](https://github.com/whnnick/readydownloader/actions/runs/31465042120): Swift 5.10 tests and download integration passed.
- [ReadyDownloader v0.1.4](https://github.com/whnnick/readydownloader/releases/tag/v0.1.4): the three public assets were downloaded independently and both packages passed `SHA256SUMS.txt` verification.
- The GitHub virtual runner reports that its VideoToolbox compression session is unavailable; CI records that boundary after verifying download and merge, while the real-Mac package check remains strict and passes H.264/AAC conversion.
- The public package is ad-hoc signed and explicitly marked as not Apple-notarized because the repository has no Apple release credentials.
- `./script/scan_repository.sh`, `bash -n script/*.sh`, and `git diff --check`: passed.
- `shasum -a 256 -c SHA256SUMS.txt`: both release artifacts passed.

## Verification remaining

- A Windows x64 build on Windows 10 or later.
- Launch and exercise the packaged app on a real macOS 13 Apple Silicon Mac.

# 0.1.4 Black-Box Functional Check

| Product area | Status | Evidence |
| --- | --- | --- |
| macOS product name | Complete | The real app window, menu-bar app name, process, bundle, and executable are ReadyDownloader |
| macOS bundle identity | Complete | Built and packaged apps report `CFBundleIdentifier` as `com.readydownloader.app` |
| Swift package and tests | Complete | ReadyDownloader and ReadyDownloaderTests build; 30 tests in 7 suites pass |
| Windows project metadata | Partial | Solution, project, namespace, target, window class, and executable names are updated; a Windows build still requires Windows |
| GitHub Actions | Complete | Workflow names, release title, expected artifacts, security link, and canonical repository URLs use ReadyDownloader |
| ReadySuite handoff | Complete | Product key, route, repository, latest-release URL, and platform summary are documented |
| Release package | Complete | ReadyDownloader 0.1.4 APP/ZIP/DMG, nested signing, checksums, DMG CRC, toolchain, and compatibility conversion checks pass |
| Repository release hygiene | Complete | Version consistency, shell syntax, sensitive-information scan, legacy-name search, and Git diff checks pass |
| GitHub remote | Blocked | `whnnick/readydownloader` does not yet exist; creating or publishing it is a separate external action |

## Verification evidence

- `swift test --package-path apps/macos`: 30 tests in 7 suites passed.
- `./script/build_and_run.sh --verify`: the ReadyDownloader process launched successfully.
- Real UI inspection confirmed the ReadyDownloader window title, header, application menu, and Chinese workflow.
- `./script/package_macos.sh`: ReadyDownloader 0.1.4 signing, ZIP/DMG, checksums, package audit, and H.264 compatibility conversion passed.
- `./script/scan_repository.sh`, `bash -n script/*.sh`, and `git diff --check`: passed.
- `shasum -a 256 -c SHA256SUMS.txt`: both release artifacts passed.

## Verification remaining

- A Windows x64 build on Windows 10 or later.
- Create the GitHub repository, push `main`, then confirm Actions and the public latest-release URL.

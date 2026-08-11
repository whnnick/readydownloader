# 0.1.4 黑盒功能检查

| 功能区域 | 状态 | 验证证据 |
| --- | --- | --- |
| macOS 产品名称 | 已完成 | 真实 APP 窗口、菜单栏应用名、进程、Bundle 和可执行文件均为 ReadyDownloader |
| macOS Bundle 标识 | 已完成 | 构建及发布 APP 的 `CFBundleIdentifier` 均为 `com.readydownloader.app` |
| Swift Package 与测试 | 已完成 | ReadyDownloader 与 ReadyDownloaderTests 构建通过；30 个测试、7 个测试套件通过 |
| macOS 运行兼容性 | 部分完成 | SwiftPM 与 Mach-O 可执行文件最低目标均为 macOS 13.0；仍需 macOS 13 实机启动验证 |
| Swift 工具链兼容性 | 已完成 | GitHub macOS 14 / Swift 5.10 runner 已完成 Package 构建，并通过全部 30 个 XCTest 测试 |
| Windows 工程元数据 | 部分完成 | 解决方案、工程、命名空间、Target、窗口类和可执行文件名已更新；仍需 Windows 实机编译 |
| GitHub Actions | 已完成 | CI 运行 31471323256 与 Release 运行 31471639759 均已通过 |
| ReadySuite 交接 | 已完成 | 产品标识、路由、仓库、最新版下载 URL 和平台摘要已经记录 |
| 发布包 | 已完成 | ReadyDownloader 0.1.4 APP/ZIP/DMG、内嵌签名、校验和、DMG CRC、工具链和兼容转换检查通过 |
| 仓库发布卫生 | 已完成 | 版本一致性、Shell 语法、敏感信息扫描、旧名称检索和 Git Diff 检查通过 |
| GitHub 远端 | 已完成 | 公开仓库 `whnnick/readydownloader` 已创建，`main` 已成为本地跟踪分支，完整提交历史已推送 |
| GitHub Release | 已完成 | 公开 `v0.1.4` 已是 latest、非草稿、非预发布，并包含 DMG、ZIP 与校验文件 |

## 验证证据

- `swift test --package-path apps/macos`：30 个测试、7 个测试套件通过。
- `vtool -show-build ReadyDownloader`：可执行文件报告 `minos 13.0`。
- `./script/build_and_run.sh --verify`：ReadyDownloader 进程启动成功。
- 真实界面检查确认 ReadyDownloader 窗口标题、页面品牌、应用菜单和中文工作流。
- `./script/package_macos.sh`：ReadyDownloader 0.1.4 签名、ZIP/DMG、校验和、包审计和 H.264 兼容转换通过。
- [GitHub Actions 运行 31465042120](https://github.com/whnnick/readydownloader/actions/runs/31465042120)：Swift 5.10 测试和下载集成验证通过。
- [ReadyDownloader v0.1.4](https://github.com/whnnick/readydownloader/releases/tag/v0.1.4)：已独立下载三个公开产物，两个安装包均通过 `SHA256SUMS.txt` 验证。
- GitHub 虚拟 runner 明确报告其 VideoToolbox 压缩会话不可用；CI 在完成下载与合并验证后记录这一环境边界，真实 Mac 上的发布包检查仍保持严格并通过 H.264/AAC 转换。
- 由于仓库尚未配置 Apple 发布凭据，公开安装包采用 ad-hoc 签名，并已明确标注未经 Apple 公证。
- `./script/scan_repository.sh`、`bash -n script/*.sh` 和 `git diff --check`：通过。
- `shasum -a 256 -c SHA256SUMS.txt`：两个发布产物均通过。

## 待验证内容

- 在 Windows 10 或更高版本完成 Windows x64 编译。
- 在真实 macOS 13 Apple Silicon Mac 上启动并操作发布包。

# 发布指南

macOS 是主发布线。除非版本明确宣传为双平台发布，否则 Windows 兼容工作不会阻塞
Mac 版本。
规范 GitHub 仓库 slug 为 `whnnick/readydownloader`。

## 本地发布验证

环境要求：

- macOS 13 或更高版本的 Apple Silicon Mac；
- Xcode 命令行工具；
- Python 3、`curl`、`make`、`tar`、`ditto` 和 `hdiutil`；
- 足够的磁盘空间用于从源码构建 FFmpeg。

执行：

```bash
./script/prepare_macos_tools.sh
./script/package_macos.sh
```

第一个命令下载固定版本输入并逐项校验 SHA-256，然后从 FFmpeg 8.1.2 官方源码
构建不启用 GPL 或非自由外部库的工具，并明确启用 Apple 的 VideoToolbox H.264
编码器，供 macOS 的 iPhone 兼容下载模式使用。未设置 `MACOS_SIGNING_IDENTITY` 时，
第二个命令生成 ad-hoc 签名的开发验证包。打包前还会在本机提供生成的 DASH
独立音视频流，使用固定版本 yt-dlp 的最佳画质选择器下载，验证合并结果，再经
VideoToolbox 转换并使用内嵌 FFprobe 确认成品为 H.264、AAC 和 yuv420p。

构建流程会从仓库跟踪的 1024×1024 品牌主图生成 `AppIcon.icns`。发布包验证会
同时检查图标资源和对应的 `CFBundleIconFile` 配置。

预期产物：

```text
dist/release/
├── ReadyDownloader-<version>-macos-arm64.dmg
├── ReadyDownloader-<version>-macos-arm64.zip
└── SHA256SUMS.txt
```

打包前会清空发布目录，完成后必须只包含上述三个当前版本文件。

## Developer ID 签名与公证

先将公证凭据保存到登录钥匙串：

```bash
xcrun notarytool store-credentials ReadyDownloader-notary
```

然后执行：

```bash
MACOS_SIGNING_IDENTITY="Developer ID Application: Example (TEAMID)" \
MACOS_NOTARY_PROFILE="ReadyDownloader-notary" \
REQUIRE_GATEKEEPER=1 \
./script/package_macos.sh
```

脚本会依次签名内嵌可执行文件、只为 Deno 配置必需的 JIT 运行时例外、使用
Hardened Runtime 签名 App、提交并装订 App、公证并装订 DMG、验证
Gatekeeper，最后生成校验文件。

## GitHub Release

GitHub Release 由 `https://github.com/whnnick/readydownloader` 发布。
ReadySuite 产品下载入口应使用
`https://github.com/whnnick/readydownloader/releases/latest`。

如需发布 Developer ID 签名并完成 Apple 公证的版本，必须完整配置以下仓库
Secrets：

- `MACOS_CERTIFICATE_P12_BASE64`
- `MACOS_CERTIFICATE_PASSWORD`
- `MACOS_SIGNING_IDENTITY`
- `APPLE_ID`
- `APPLE_TEAM_ID`
- `APPLE_APP_SPECIFIC_PASSWORD`

创建 Tag 前：

1. 完成当前版本黑盒检查报告。
2. 将中英文更新日志中当前 `VERSION` 对应条目的“未发布”改为发布日期。
3. 确认 `VERSION` 与计划创建的 Tag 一致。
4. 提交并推送干净的 `main`。
5. 创建并推送 `v<version>`。

如果更新日志仍标记为未发布，或 Apple 凭据只配置了一部分，工作流会主动失败。
六项凭据完整时发布 Developer ID 签名并公证的安装包；六项均未配置时，发布明确
标注的 ad-hoc 签名、未公证安装包。发布后，工作流会重新下载公开产物、校验
SHA-256、要求恰好包含三个产物，并确认该 Tag 是 GitHub 最新版本。

### Release 同步约束

准备发布的版本不能只停留在推送 `main`。同一次发布操作必须推送 `v<version>`、
创建对应 GitHub Release、上传 ZIP、DMG 与 `SHA256SUMS.txt`，并验证公开的
`latest` 地址。任一步骤无法完成时，更新日志必须继续标记为“未发布”，且不得将
该版本宣传为可下载版本。

## 第三方组件

固定版本清单位于 `packaging/macos-arm64-tools.conf`。

- yt-dlp 2026.07.04：官方 macOS 独立二进制；
- Deno 2.9.4：官方 Apple Silicon 二进制；
- FFmpeg 和 ffprobe 8.1.2：从官方源码构建，不启用 GPL 或非自由外部库。

每个发布包都会包含项目许可证、第三方说明、yt-dlp 生成的第三方许可证集合，
以及 Deno 和 FFmpeg 的许可证文本。yt-dlp 独立二进制包含 GPLv3+ 组件，该
内嵌组件仍适用其自身许可证条款。

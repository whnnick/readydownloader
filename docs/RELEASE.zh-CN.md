# 发布指南

macOS 是主发布线。除非版本明确宣传为双平台发布，否则 Windows 兼容工作不会阻塞
Mac 版本。

## 本地发布验证

环境要求：

- macOS 14 或更高版本的 Apple Silicon Mac；
- Xcode 命令行工具；
- Python 3、`curl`、`make`、`tar`、`ditto` 和 `hdiutil`；
- 足够的磁盘空间用于从源码构建 FFmpeg。

执行：

```bash
./script/prepare_macos_tools.sh
./script/package_macos.sh
```

第一个命令下载固定版本输入并逐项校验 SHA-256，然后从 FFmpeg 8.1.2 官方源码
构建不启用 GPL 或非自由外部库的工具。未设置 `MACOS_SIGNING_IDENTITY` 时，
第二个命令生成 ad-hoc 签名的开发验证包。打包前还会在本机提供生成的 DASH
独立音视频流，使用固定版本 yt-dlp 的最佳画质选择器下载，并通过内嵌 FFprobe
验证合并结果。

构建流程会从仓库跟踪的 1024×1024 品牌主图生成 `AppIcon.icns`。发布包验证会
同时检查图标资源和对应的 `CFBundleIconFile` 配置。

预期产物：

```text
dist/release/
├── YouTubeDlpDownloader-<version>-macos-arm64.dmg
├── YouTubeDlpDownloader-<version>-macos-arm64.zip
└── SHA256SUMS.txt
```

打包前会清空发布目录，完成后必须只包含上述三个当前版本文件。

## Developer ID 签名与公证

先将公证凭据保存到登录钥匙串：

```bash
xcrun notarytool store-credentials YouTubeDlpDownloader-notary
```

然后执行：

```bash
MACOS_SIGNING_IDENTITY="Developer ID Application: Example (TEAMID)" \
MACOS_NOTARY_PROFILE="YouTubeDlpDownloader-notary" \
REQUIRE_GATEKEEPER=1 \
./script/package_macos.sh
```

脚本会依次签名内嵌可执行文件、只为 Deno 配置必需的 JIT 运行时例外、使用
Hardened Runtime 签名 App、提交并装订 App、公证并装订 DMG、验证
Gatekeeper，最后生成校验文件。

## GitHub Release

Tag 发布工作流需要配置以下仓库 Secrets：

- `MACOS_CERTIFICATE_P12_BASE64`
- `MACOS_CERTIFICATE_PASSWORD`
- `MACOS_SIGNING_IDENTITY`
- `APPLE_ID`
- `APPLE_TEAM_ID`
- `APPLE_APP_SPECIFIC_PASSWORD`

创建 Tag 前：

1. 完成当前版本黑盒检查报告。
2. 将中英文更新日志中 `0.1.0` 的“未发布”改为发布日期。
3. 确认 `VERSION` 与计划创建的 Tag 一致。
4. 提交并推送干净的 `main`。
5. 创建并推送 `v<version>`。

如果更新日志仍标记为未发布，或缺少 Apple 凭据，工作流会主动失败。发布后，
工作流会重新下载公开产物、校验 SHA-256，并确认该 Tag 是 GitHub 最新版本。

## 第三方组件

固定版本清单位于 `packaging/macos-arm64-tools.conf`。

- yt-dlp 2026.07.04：官方 macOS 独立二进制；
- Deno 2.9.4：官方 Apple Silicon 二进制；
- FFmpeg 和 ffprobe 8.1.2：从官方源码构建，不启用 GPL 或非自由外部库。

每个发布包都会包含项目许可证、第三方说明、yt-dlp 生成的第三方许可证集合，
以及 Deno 和 FFmpeg 的许可证文本。yt-dlp 独立二进制包含 GPLv3+ 组件，该
内嵌组件仍适用其自身许可证条款。

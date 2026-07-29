<p align="center">
  <a href="./README.md">English</a> | 简体中文
</p>

<h1 align="center">YouTubeDlpDownloader</h1>

<p align="center">
  基于 yt-dlp 的 Windows 与 macOS 原生桌面下载工具。
</p>

<p align="center">
  <img alt="Platforms" src="https://img.shields.io/badge/platform-Windows%20%7C%20macOS-blue">
  <img alt="Version" src="https://img.shields.io/badge/version-0.1.0-green">
  <img alt="License" src="https://img.shields.io/badge/license-MIT-lightgrey">
</p>

> [!IMPORTANT]
> macOS 是项目的主产品线。Windows 客户端作为兼容实现继续维护，并按共享行为契约跟进，但不会阻塞 Mac 发布。

## 主要功能

- 通过 yt-dlp JSON 输出读取视频信息和可用格式。
- 显示分辨率、帧率、编码、预估大小和码率。
- 默认下载视频可提供的最高画质，同时提供兼容 MP4 和手动格式模式。
- 当所选视频流没有音频时，通过 FFmpeg 合并最佳音频。
- 支持直连、系统代理和自定义代理。
- 可选导入 Netscape 格式 Cookie，用于需要登录会话的内容。
- 显示下载进度和可操作的错误提示。

## 平台状态

| 平台 | 技术 | 状态 |
| --- | --- | --- |
| macOS 14+ Apple Silicon | Swift 6 与 SwiftUI | 主平台；下载 MVP 与可复现打包已实现 |
| Windows x64 | C++17 与 Win32 | 兼容平台；已有原型 |

详细内容见 [v0.1.0 概览](./docs/versions/0.1.0/README.zh-CN.md)、[产品需求](./docs/versions/0.1.0/REQUIREMENTS.zh-CN.md)和[实施计划](./docs/versions/0.1.0/PLAN.zh-CN.md)。

## 构建当前 Windows 原型

环境要求：

- Windows 10 或更高版本
- Visual Studio 2022，并安装“使用 C++ 的桌面开发”工作负载
- Windows 10 SDK

打开 `YouTubeDlpDownloader.sln`，选择 `Release | x64` 后构建。

当前运行目录结构：

```text
YouTubeDlpDownloader.exe
tools/
├── yt-dlp.exe
├── deno.exe
└── ffmpeg/bin/
    ├── ffmpeg.exe
    └── ffprobe.exe
config/
└── yt_cookies.txt       # 可选的用户私密数据，严禁提交
Downloads/
```

工具二进制、Cookie、下载内容和构建产物均通过 `.gitignore` 排除。

## 构建 macOS 应用

运行测试：

```bash
swift test --package-path apps/macos --disable-sandbox
```

构建并启动 `.app` Bundle：

```bash
./script/build_and_run.sh
```

Mac 应用已经实现格式查询、不限制分辨率的最佳画质下载、兼容 MP4、手动格式、实时进度、取消、持久保存目录选择、Finder 定位和主动开启的 yt-dlp 详细日志。Apple Silicon 工具版本锁定以及 APP/ZIP/DMG 本地打包已实现；签名和公证的公开产物仍需要 Apple 发布凭据。

## 文档

- [v0.1.0 版本概览](./docs/versions/0.1.0/README.zh-CN.md)
- [产品需求](./docs/versions/0.1.0/REQUIREMENTS.zh-CN.md)
- [技术架构](./docs/versions/0.1.0/ARCHITECTURE.zh-CN.md)
- [实施计划](./docs/versions/0.1.0/PLAN.zh-CN.md)
- [黑盒功能检查](./docs/versions/0.1.0/BLACK_BOX_TESTS.zh-CN.md)
- [发布指南](./docs/RELEASE.zh-CN.md)
- [贡献指南](./CONTRIBUTING.md)
- [安全政策](./SECURITY.md)
- [第三方软件说明](./THIRD_PARTY_NOTICES.md)

## 合规使用

仅使用本软件下载你拥有或已获授权下载的内容。使用者有责任遵守适用法律、网站条款、版权和隐私要求。本项目不提供 DRM 绕过功能。

提交 GitHub Issue 时，不要附带 Cookie、账号令牌、私密链接或下载的私密媒体。

## 许可证

本项目采用 [MIT License](./LICENSE)。

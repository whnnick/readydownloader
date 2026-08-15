<p align="center">
  <a href="./README.md">English</a> | 简体中文
</p>

<p align="center">
  <img src="./assets/branding/AppIcon.png" width="128" alt="ReadyDownloader 应用图标">
</p>

<h1 align="center">ReadyDownloader</h1>

<p align="center">
  ReadySuite 旗下覆盖 Web、macOS 与 Windows 的视频下载工具。
</p>

<p align="center">
  <img alt="Platforms" src="https://img.shields.io/badge/platform-Web%20%7C%20macOS%20%7C%20Windows-blue">
  <img alt="Version" src="https://img.shields.io/badge/version-0.2.1-green">
  <img alt="License" src="https://img.shields.io/badge/license-MIT-lightgrey">
  <a href="https://github.com/whnnick/readydownloader/actions/workflows/macos-ci.yml"><img alt="macOS CI" src="https://github.com/whnnick/readydownloader/actions/workflows/macos-ci.yml/badge.svg"></a>
</p>

<p align="center">
  <a href="https://github.com/whnnick/readydownloader">源码</a> ·
  <a href="https://readydownloader.vercel.app/">Web 版</a> ·
  <a href="https://github.com/whnnick/readydownloader/releases/latest">最新版本</a> ·
  <a href="https://github.com/whnnick/readydownloader/issues">问题反馈</a> ·
  <a href="https://readysuite.vercel.app/">ReadySuite</a>
</p>

> [!IMPORTANT]
> macOS 是项目的主产品线。Windows 客户端作为兼容实现继续维护，并按共享行为契约跟进，但不会阻塞 Mac 发布。

## 快速开始

打开 [readydownloader.vercel.app](https://readydownloader.vercel.app/) 即可免安装使用中英文 Web 版。粘贴受支持的公开视频链接，解析画质后选择最高画质、iPhone 兼容或指定格式。

从 [GitHub Releases](https://github.com/whnnick/readydownloader/releases/latest) 下载当前 macOS 安装包，将 `ReadyDownloader.app` 移入“应用程序”后打开。当前公开安装包目标为 macOS 13 及以上版本的 Apple Silicon Mac。

当前安装包采用 ad-hoc 签名且未经 Apple 公证。如果 macOS 首次启动时拦截，请在
Finder 中按住 Control 点击应用，选择“打开”并确认一次；不要全局关闭 Gatekeeper。

## 主要功能

- 通过 yt-dlp JSON 输出读取视频信息和可用格式。
- 显示分辨率、帧率、编码、预估大小和码率。
- 默认下载视频可提供的最高画质，同时提供 iPhone 兼容和手动格式模式。
- 检查 iPhone 兼容下载的成品编码，将不兼容的 VP9/AV1 视频转为 H.264、已有音频转为 AAC，并统一为 yuv420p。
- 当所选视频流没有音频时，通过 FFmpeg 合并最佳音频。
- 支持直连、系统代理和自定义代理。
- 可选导入 Netscape 格式 Cookie，用于需要登录会话的内容。
- 显示下载进度和可操作的错误提示。

## 平台状态

| 平台 | 技术 | 状态 |
| --- | --- | --- |
| Web | Next.js 16、Vercel Functions、私有 Vercel Blob | 已在 `readydownloader.vercel.app` 上线；已实现公开视频核心流程 |
| macOS 13+ Apple Silicon | Swift 5.10+ 与 SwiftUI | 主平台；下载 MVP 与可复现打包已实现 |
| Windows x64 | C++17 与 Win32 | 兼容平台；已有原型 |

Web 版与客户端对齐格式解析和三种下载模式。受浏览器与服务端安全边界限制，Web 版有意不接收 Cookie、不访问私密或登录内容、不提供自定义代理和任意本地目录选择，也不处理 DRM 内容。成品上限为 500 MB，存入私有空间，通过限时签名链接提供，并计划在 24 小时后删除。

生产 Web 版使用与 ReadySuite 相同的 Vercel Web Analytics。埋点只包含粗粒度产品上下文，不会发送视频链接、标题、文件名、访问令牌、签名下载地址或原始错误；自定义事件面板需要 Vercel 支持该能力的套餐。详见[统计与隐私边界](./docs/versions/0.2.1/ANALYTICS.zh-CN.md)。

详细内容见 [v0.1.0 概览](./docs/versions/0.1.0/README.zh-CN.md)、[产品需求](./docs/versions/0.1.0/REQUIREMENTS.zh-CN.md)和[实施计划](./docs/versions/0.1.0/PLAN.zh-CN.md)。

当前随包 yt-dlp 包含 YouTube、哔哩哔哩、TikTok、Instagram、Facebook、
X/Twitter、Vimeo、Twitch、Reddit、AcFun、斗鱼、虎牙、爱奇艺、优酷和微博等
主流服务的提取器。是否可用取决于具体链接，并非永久保证；详见
[支持站点边界](./docs/versions/0.1.0/SUPPORTED_SITES.zh-CN.md)。

## 构建当前 Windows 原型

环境要求：

- Windows 10 或更高版本
- Visual Studio 2022，并安装“使用 C++ 的桌面开发”工作负载
- Windows 10 SDK

打开 `ReadyDownloader.sln`，选择 `Release | x64` 后构建。

当前运行目录结构：

```text
ReadyDownloader.exe
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

Mac 应用已提供与 ReadyType 统一、可在简体中文和 English 间即时切换的下载流程，并实现格式查询、不限制分辨率的最佳画质下载、经过编码验证的 iPhone 兼容 H.264 MP4、手动格式、实时进度、取消、持久保存目录选择、Finder 定位和主动开启的 yt-dlp 详细日志。Apple Silicon 工具版本锁定以及 APP/ZIP/DMG 本地打包已实现；签名和公证的公开产物仍需要 Apple 发布凭据。

## 构建 Web 版

```bash
cd apps/web
npm ci
npm test
npm run check
npm run build
npm run dev
```

Vercel Blob、环境变量、保留时间和生产验收要求见 [Web 部署指南](./docs/versions/0.2.0/WEB_DEPLOYMENT.zh-CN.md)。

## ReadySuite 集成

产品唯一标识为 `readydownloader`，Web 生产地址为 `https://readydownloader.vercel.app`，计划使用的 ReadySuite 产品目录路由为 `/readydownloader`。桌面端下载入口应指向 `https://github.com/whnnick/readydownloader/releases/latest`。ReadySuite 网站继续使用独立仓库和发布流程。

## 文档

- [v0.2.1 版本概览](./docs/versions/0.2.1/README.zh-CN.md)
- [v0.2.1 黑盒功能检查](./docs/versions/0.2.1/BLACK_BOX_TESTS.zh-CN.md)
- [统计与隐私边界](./docs/versions/0.2.1/ANALYTICS.zh-CN.md)
- [Web 部署指南](./docs/versions/0.2.0/WEB_DEPLOYMENT.zh-CN.md)
- [产品需求](./docs/versions/0.1.0/REQUIREMENTS.zh-CN.md)
- [技术架构](./docs/versions/0.1.0/ARCHITECTURE.zh-CN.md)
- [实施计划](./docs/versions/0.1.0/PLAN.zh-CN.md)
- [支持站点边界](./docs/versions/0.1.0/SUPPORTED_SITES.zh-CN.md)
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

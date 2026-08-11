# ReadyDownloader 0.1.0

`0.1.0` 是计划中的首个公开双平台版本。

## 版本目标

提供一个可信的 yt-dlp 原生桌面界面，支持：

- Windows 10+ x64；
- macOS 14+ Apple Silicon。

两个客户端必须实现相同的核心流程：查询单个媒体链接、查看视频格式、选择输出、显示下载进度、必要时合并音频，并能定位完成的文件。

## 文档

- [产品需求](./REQUIREMENTS.zh-CN.md)
- [技术架构](./ARCHITECTURE.zh-CN.md)
- [实施计划](./PLAN.zh-CN.md)
- [支持站点边界](./SUPPORTED_SITES.zh-CN.md)
- [黑盒功能检查](./BLACK_BOX_TESTS.zh-CN.md)
- [发布指南](../../RELEASE.zh-CN.md)
- [English](./README.md)

## 当前状态

状态：macOS 实施与发布准备中。

macOS 下载 MVP、本地 SwiftUI 全流程验收和可复现本地打包已经实现，但已获授权的公开链接以及签名、公证后的产物仍需完成真实环境验收并配置 Apple 发布凭据。Windows 代码仍是兼容原型，不阻塞仅发布 Mac 的 `v0.1.0`。

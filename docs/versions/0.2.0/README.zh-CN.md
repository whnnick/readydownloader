# ReadyDownloader 0.2.0

`0.2.0` 新增生产可用的 Web 应用，同时继续以 macOS 作为原生主产品线。

## 已交付

- 生产地址：[readydownloader.vercel.app](https://readydownloader.vercel.app/)
- 与 ReadyType 风格统一的简体中文和 English 界面
- 公共媒体解析和可选择的格式表
- 最高画质、iPhone 兼容和指定格式三种模式
- 服务端 yt-dlp、FFmpeg 合并，以及 H.264/AAC/yuv420p 兼容转换
- 私有 Blob 成品、限时签名链接和定时删除
- 来源白名单、SSRF 防护、限速、取消和 500 MB 成品上限
- Linux 与 macOS yt-dlp 固定为 `2026.07.04` 并校验 SHA-256

## 平台边界

Web 版对齐客户端的公开视频核心流程，但有意不接收 Cookie，不访问私密或登录内容，不支持自定义代理、任意本地下载目录、播放列表或 DRM 内容。来源站点变化、地区限制和反机器人策略仍可能使单个链接不可用。

## 文档

- [黑盒功能检查](./BLACK_BOX_TESTS.zh-CN.md)
- [Web 部署指南](./WEB_DEPLOYMENT.zh-CN.md)
- [发布指南](../../RELEASE.zh-CN.md)

# 0.2.0 黑盒功能检查

日期：2026-08-15

| 需求 | 状态 | 证据 |
| --- | --- | --- |
| Web 生产应用 | 已完成 | `https://readydownloader.vercel.app` 返回 HTTP 200，Vercel 部署状态为 READY |
| 中英文界面 | 已完成 | 全新浏览器会话验证两种语言、当前状态同步翻译和页面标题本地化 |
| 桌面与移动布局 | 已完成 | Playwright 验证生产环境 1440×1000 与 390×844 视口 |
| 浏览器画质流程 | 已完成 | 已提供链接校验、三种模式、格式表、取消、进度和签名成品操作 |
| Instagram 解析 | 已完成 | 用户报告的公开 Reel 在本地与生产环境均返回八个格式 |
| iPhone 兼容 | 已完成 | 生产链路依次完成下载、转换、上传和完成阶段；FFprobe 确认为 MP4、H.264、AAC 和 yuv420p |
| 临时存储 | 已完成 | 成品进入私有 Blob 并使用限时签名链接；冒烟测试 Blob 已在验收后删除 |
| 网络安全 | 已完成 | 本地和私有网络地址被拦截，仅接受批准的公共来源域名 |
| 自动检查 | 已完成 | 本地 27 个 Vitest 测试、TypeScript 检查和 Next.js 生产构建通过 |
| macOS 回归与安装包 | 已完成 | 30 个 XCTest 通过；0.2.0 APP/ZIP/DMG、签名、校验和、DMG CRC、工具链、合并与兼容转换检查通过 |
| GitHub Actions | 已完成 | Web CI 运行 31859279049、macOS CI 运行 31859279065 和 Release 运行 31859428814 均通过 |
| GitHub Release | 已完成 | 公开 `v0.2.0` 已是 latest、非草稿、非预发布，并包含 DMG、ZIP 与校验文件 |
| 浏览器控制台 | 已完成 | 生产桌面与移动会话均为零错误、零警告 |

## 已知边界

- Web 请求不接收 Cookie，不能访问私密、仅登录或 DRM 内容。
- 最终本地保存目录由浏览器管理。
- 采用 500 MB 成品上限、单视频且不处理播放列表、尽力型限速和 24 小时保留规则。
- 是否可用仍取决于具体 URL、地区和提取器状态。
- 除非配置 Apple 发布凭据，macOS 公开产物仍为 ad-hoc 签名且未经 Apple 公证。

## 发布结果

已通过。远端 `main` 与展开后的 `v0.2.0` Tag 均指向提交 `048ee72530ec26b9bcc75e1481dab6f1fca49bbe`。[v0.2.0 GitHub Release](https://github.com/whnnick/readydownloader/releases/tag/v0.2.0) 已公开并成为 latest，恰好包含三个产物；独立下载后通过 `SHA256SUMS.txt` 校验。Vercel 部署 `dpl_CtyJpy9PQbvUNKiPV29GuVxrxgQw` 状态为 READY，并已绑定规范生产地址。

# 0.2.1 黑盒功能检查

日期：2026-08-15

| 要求 | 状态 | 证据 |
| --- | --- | --- |
| 与 ReadySuite 一致的统计 | 已完成 | Vercel Web Analytics 已启用；生产统计脚本、页面访问与自定义事件请求均返回 HTTP 200 |
| 隐私安全的自定义事件 | 源码已完成 | 类型化双字段白名单与载荷测试排除了媒体输入、令牌、文件名、签名地址和原始错误；面板采集需要 Pro 或 Enterprise |
| Speed Insights | 部分完成 | 接入代码已存在；Hobby 团队的项目名额限制阻止生产启用 |
| 自动化检查 | 已完成 | 本地 30 个 Vitest 测试、TypeScript 检查和 Next.js 生产构建通过 |
| 发布同步 | 已完成 | 源码、Tag、GitHub Release、三个产物、独立校验和、latest 与生产部署均已验证 |
| 浏览器控制台 | 已完成 | 生产统计浏览器会话无错误、无警告 |
| GitHub Actions | 已完成 | Web CI 31861002305、macOS CI 31861002237 和 Release 31861194055 均通过 |
| 部署后错误 | 已完成 | 验收后的 15 分钟窗口未记录生产错误 |

## 已知边界

当前 Hobby 团队无法为第二个项目启用 Vercel Speed Insights。现有 ReadySuite 性能监控保持不变。

Hobby 套餐可以继续使用 Vercel Web Analytics 页面访问统计；自定义事件需要 Pro 或 Enterprise。

## 生产证据

部署 `dpl_3ubhPXJ8egbvmCdRBSwXfMrorZKC` 已达到 READY，并绑定 `https://readydownloader.vercel.app`。允许普通访客采集的浏览器会话中，第一方统计脚本与 `/view` 端点均返回 HTTP 200；切换到英文后，`language_change` 请求只包含 `{ "language": "en" }`，`/event` 端点同样返回 HTTP 200。

## 发布结果

通过。展开后的 `v0.2.1` Tag 指向 `4e77bb49d01131ce6f5c5262edebc9a0c2758263`，远端 `main` 包含该发布提交以及本次发布后证据。[v0.2.1 GitHub Release](https://github.com/whnnick/readydownloader/releases/tag/v0.2.1) 已公开并成为 latest，恰好包含三个产物；独立下载的 DMG 与 ZIP 均通过 `SHA256SUMS.txt` 校验。

# 0.2.1 黑盒功能检查

日期：2026-08-15

| 要求 | 状态 | 证据 |
| --- | --- | --- |
| 与 ReadySuite 一致的统计 | 已完成 | Vercel Web Analytics 已启用；生产统计脚本、页面访问与自定义事件请求均返回 HTTP 200 |
| 隐私安全的自定义事件 | 源码已完成 | 类型化双字段白名单与载荷测试排除了媒体输入、令牌、文件名、签名地址和原始错误；面板采集需要 Pro 或 Enterprise |
| Speed Insights | 部分完成 | 接入代码已存在；Hobby 团队的项目名额限制阻止生产启用 |
| 自动化检查 | 已完成 | 本地 30 个 Vitest 测试、TypeScript 检查和 Next.js 生产构建通过 |
| 发布同步 | 进行中 | 生产部署已完成；源码推送、Tag、Release 产物、校验和与 latest 验证待完成 |
| 浏览器控制台 | 已完成 | 生产统计浏览器会话无错误、无警告 |

## 已知边界

当前 Hobby 团队无法为第二个项目启用 Vercel Speed Insights。现有 ReadySuite 性能监控保持不变。

Hobby 套餐可以继续使用 Vercel Web Analytics 页面访问统计；自定义事件需要 Pro 或 Enterprise。

## 生产证据

部署 `dpl_3ubhPXJ8egbvmCdRBSwXfMrorZKC` 已达到 READY，并绑定 `https://readydownloader.vercel.app`。允许普通访客采集的浏览器会话中，第一方统计脚本与 `/view` 端点均返回 HTTP 200；切换到英文后，`language_change` 请求只包含 `{ "language": "en" }`，`/event` 端点同样返回 HTTP 200。

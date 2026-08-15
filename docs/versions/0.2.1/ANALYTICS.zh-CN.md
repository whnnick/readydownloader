# 统计与隐私边界

ReadyDownloader Web 使用与 ReadySuite 网站相同的 Vercel Web Analytics。除自动页面访问外，只采集以下自定义事件：

| 事件 | 允许的自定义字段 |
| --- | --- |
| `analyze_click`、`analyze_error` | 语言 |
| `analyze_complete` | 语言、汇总格式数量 |
| `download_click`、`download_complete`、`download_error` | 语言、下载模式 |
| `file_save_click` | 语言、下载模式 |
| `github_click`、`language_change` | 语言 |

视频链接、页面标题、输出文件名、访问令牌、Blob 签名地址、格式 ID 和原始错误不会写入自定义事件。统计必须是非阻塞的，不能改变下载行为。

应用布局已挂载 Speed Insights。当前 Hobby 团队只允许一个项目启用该能力，因此在迁移现有名额或升级团队套餐前，ReadyDownloader 的生产性能采集保持未启用。

当前 Hobby 套餐可以采集 Web Analytics 页面访问。Vercel 自定义事件需要 Pro 或 Enterprise，因此产品漏斗埋点只有在升级套餐后才会显示。

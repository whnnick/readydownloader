# 0.1.0 支持站点边界

## 当前快照

macOS 安装包固定使用
[yt-dlp 2026.07.04](https://github.com/yt-dlp/yt-dlp/releases/tag/2026.07.04)。
该随包程序当前列出 1,752 个提取器标识。这不等于 1,752 个保证可用的网站：
一个平台可能对应多个提取器，而且网站会持续改版。

yt-dlp 的[官方支持站点列表](https://github.com/yt-dlp/yt-dlp/blob/master/supportedsites.md)
同样说明：出现在列表里不代表保证可用，可靠方法只有测试具体链接。部分未列出的
嵌入播放器和直接媒体地址也可能通过通用提取器工作。

## 当前随包版本包含的代表性提取器

| 范围 | 当前随包版本检测到的示例 | 当前 App 边界 |
| --- | --- | --- |
| 主流视频和社交平台 | YouTube、哔哩哔哩、TikTok、Instagram、Facebook、X/Twitter、Reddit | 每次处理一个直接媒体链接；登录或受限内容可能需要用户导出的 Cookie 文件 |
| 视频托管平台 | Vimeo、Dailymotion、Rumble、VK | 平台提取器仍有效时，可处理公开且无 DRM 的媒体 |
| 国内平台 | AcFun、斗鱼、虎牙、爱奇艺、优酷、微博 | 公开或用户有权访问的无 DRM 内容；VIP、地区和登录限制仍然有效 |
| 直播和 VOD | Twitch、斗鱼、虎牙、Niconico | 已包含提取器，但长时间直播下载尚未完成发布验收 |
| 广播与媒体机构 | BBC、CNN、ABC 系列服务及大量地区媒体 | 是否可用取决于国家地区、账号和媒体保护方式 |
| 音频与播客 | SoundCloud、Bandcamp、Mixcloud、Apple Podcasts | 已包含提取器，但 v0.1.0 以视频为主，暂不对外承诺纯音频 UI 支持 |
| 嵌入或直接媒体流 | 通用嵌入视频、HLS、DASH 链接 | yt-dlp 能发现未受保护的媒体流时可以工作 |

本地生成的 DASH 测试已经通过 macOS 格式查询、最佳画质下载、音视频合并、
保存目录选择和 Finder 定位全流程。2026-07-30 检查时，yt-dlp FAQ 当前展示的
公开测试视频返回 `Video unavailable`，因此没有把它计为公开平台验收通过。

## 不保证或不在当前范围

- 绕过 DRM；
- 在用户没有有效权限时下载已删除、私密、付费、年龄限制或地区限制内容；
- 平台改版或 API 变化后仍能持续工作；
- 播放列表、频道、队列或批量下载——当前 App 会传入 `--no-playlist`；
- 浏览器 Cookie 自动提取、OAuth 登录、验证码处理或外部 Token 服务；
- v0.1.0 的直播录制可靠性；
- 当前视频格式表中的纯音频格式浏览。

随着上游限制变化，部分 YouTube 格式可能需要 Cookie 或 PO Token。App 已随包
提供 Deno 和 FFmpeg，用于 JavaScript 提取以及最高画质音视频合并，但不会生成
PO Token，也不会绕过平台访问控制。更多限制见 yt-dlp 官方
[提取器说明](https://github.com/yt-dlp/yt-dlp/wiki/Extractors)和
[FAQ](https://github.com/yt-dlp/yt-dlp/wiki/FAQ)。

请仅下载你拥有或已获得授权的内容。

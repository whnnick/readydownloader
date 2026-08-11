# 0.1.3 黑盒功能检查

| 功能区域 | 状态 | 验证证据 |
| --- | --- | --- |
| 兼容媒体识别 | 已完成 | 测试接受 H.264/AAC/yuv420p MP4，并拒绝 VP9、非 AAC 音频和非 4:2:0 视频 |
| 最高画质行为 | 已完成 | 原有不限制画质的选择器保持不变 |
| iPhone 兼容转换 | 已完成 | 内嵌 FFmpeg 将不兼容视频转为 H.264/yuv420p，在存在音频时转为 AAC |
| 用户报告的 Instagram Reel | 已完成 | 源文件为 VP9/yuv420p MP4，临时转换结果为 H.264/yuv420p MP4；该源链接未提供音频流 |
| 双语处理状态 | 已完成 | 中英文兼容转换状态测试通过；真实中文 APP 已显示“iPhone 兼容”及明确的编码行为 |
| 工具链约束 | 已完成 | 工具验证同时要求 H.264 VideoToolbox 和 AAC 编码器 |
| 发布包 | 已完成 | 0.1.3 APP/ZIP/DMG、内嵌签名、校验和、DMG CRC、工具链和发布包内 H.264 转换检查通过 |

## 自动化与真实进程证据

- `swift test --package-path apps/macos`：打包前 30 个测试、7 个测试套件通过。
- `./script/test_macos_download_integration.sh`：本地 DASH 下载、合并、H.264/AAC 转换和 FFprobe 检查通过。
- `./script/package_macos.sh`：0.1.3 APP、ZIP、DMG、签名、校验和、发布包内 VideoToolbox 转换和包审计通过。
- 用户报告的公开 Instagram 链接已下载到临时目录，并在保持 720×1280 分辨率的情况下由 VP9 转为 H.264。

## 仍需真实环境验收

- 将 0.1.3 新成品分享至实体 iPhone，并在用户的目标 App 中确认播放。
- Developer ID 公证和远程 GitHub Release。

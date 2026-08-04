# 0.1.2 黑盒功能检查

| 功能区域 | 状态 | 验证证据 |
| --- | --- | --- |
| 正式包工具定位 | 已完成 | APP 内嵌工具优先，发布包审计检查 yt-dlp、Deno、FFmpeg 和 FFprobe |
| 开发构建工具回退 | 已完成 | Bundle 资源缺失时向上查找 `tools/macos-arm64` 的测试通过 |
| 中文界面 | 已完成 | 真实 APP 主窗口、设置、格式表、状态和命令检查通过 |
| 英文界面 | 已完成 | 从设置即时切换后，窗口、控件、格式表和状态全部变为英文 |
| 状态保持 | 已完成 | 切换语言后本地 DASH 的 1 个解析结果和可下载状态保持不变 |
| 错误恢复提示 | 已完成 | 中英文缺少组件提示均指向当前 DMG/ZIP 或开发工具准备流程 |
| 下载与音频合并 | 已完成 | 真实 yt-dlp 下载、FFmpeg 合并和 FFprobe 音视频轨道检查通过 |

## 自动化证据

- `swift test --package-path apps/macos`：25 个测试、6 个测试套件通过。
- `./script/test_macos_download_integration.sh`：真实本地下载与合并通过。
- `./script/package_macos.sh`：0.1.2 APP、ZIP、DMG、签名、校验和和发布包审计通过。

## 仍需真实环境验收

- 已获授权的 Instagram 等公网链接完整下载。
- 长时间公网下载取消、干净 macOS 账号、Developer ID 公证和远程 GitHub Release。

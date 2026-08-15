# 更新日志

本文件记录项目的重要变更。

格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本采用[语义化版本](https://semver.org/lang/zh-CN/)。

## [未发布]

## [0.2.1] - 2026-08-15

### 新增

- 接入与 ReadySuite 相同的 Vercel Web Analytics，包括页面访问，以及针对解析、下载、语言、保存文件和 GitHub 交互的隐私安全埋点。
- 接入 Vercel Speed Insights 代码，使团队套餐有可用名额后即可开始采集性能数据。
- 新增统计载荷自动化测试，将自定义事件限制为最多两个字段：语言，以及下载模式或汇总格式数量。

### 验证

- 已在生产 Vercel 项目启用 Web Analytics。
- 30 个 Web 测试、TypeScript 检查与 Next.js 生产构建通过。

### 已知限制

- ReadySuite 当前 Hobby 团队仅允许一个项目启用 Speed Insights。ReadyDownloader 已包含接入代码，但若不迁移现有名额或升级团队，生产性能采集暂时无法启用。
- Vercel 自定义事件仅支持 Pro 或 Enterprise。当前 Hobby 套餐会采集页面访问，但产品漏斗埋点不会出现在统计面板中。

## [0.2.0] - 2026-08-15

### 新增

- 在 `https://readydownloader.vercel.app` 上线中英文 Web 版，支持画质解析、最高画质、iPhone 兼容和指定格式三种下载模式。
- 新增私有临时 Blob、24 小时签名下载链接、定时清理、公开来源白名单、SSRF 防护、请求限速、取消和 500 MB 成品上限。
- 固定并校验 Linux 部署版与 macOS 开发版 yt-dlp，同时将静态 FFmpeg 和 FFprobe 纳入服务端函数追踪。
- 新增 Web 单元测试、TypeScript 检查、生产构建、CI，以及中英文部署和黑盒检查文档。

### 修复

- Web 的 iPhone 兼容模式会检查最终成品，并将不兼容的视频和音频转换为 MP4、H.264、存在音频时使用 AAC，以及 yuv420p。
- 切换语言时会同步更新当前状态和页面标题，同时保留已经解析的格式。
- 修复移动端横向溢出和 macOS 本地开发工具选择问题。

### 验证

- 用户报告的 Instagram Reel 已通过本地与生产 API 解析出八个格式。
- 生产环境已完成下载、转换、私有上传和限时签名链接全链路；FFprobe 确认成品为 MP4、H.264、AAC 和 yuv420p。
- `readydownloader.vercel.app` 已通过桌面与移动端浏览器验收，控制台无警告和错误，并已清理全部冒烟测试媒体。

## [0.1.4] - 2026-08-11

### 变更

- 将产品、macOS APP、Swift Package、Windows 解决方案、可执行文件和发布产物统一更名为 ReadyDownloader。
- 将 macOS Bundle ID 调整为 `com.readydownloader.app`，与 ReadySuite 产品命名规则保持一致。
- 确定 `readydownloader` 为 GitHub 仓库 slug，`/readydownloader` 为未来 ReadySuite 网站路由。
- 将 Mac 主产品线最低系统从 macOS 14 下调到 macOS 13，并将 Swift Package 工具版本从 Swift 6 下调到 Swift 5.10。
- 使用 Combine 和兼容的 SwiftUI 实现替换 macOS 14 专属的 Observation 与空状态依赖。
- 将全部 30 个测试从 Swift Testing 迁移为 XCTest，使其可在 Swift 5.10 工具链运行。

### 修复

- 发布验证现在会拒绝应用名称、可执行文件或 Bundle ID 不正确的安装包。

### 验证

- Swift 测试、构建脚本、GitHub Actions 发布产物、中英文文档和 Windows 工程元数据已同步重命名。
- 已确认可执行文件的 Mach-O 最低系统版本为 macOS 13.0，并在本地重新执行全部 30 个 XCTest 测试。
- GitHub macOS 14 / Swift 5.10 工作流已通过，包括仓库检查以及真实的本地下载与合并集成链路。
- 将 Tag 推送、GitHub Release 产物、校验和验证与公开 latest 地址检查设为必须同步完成的发布操作。

## [0.1.3] - 未发布

### 变更

- 将 macOS 的“兼容 MP4”调整为“iPhone 兼容”，并明确仅有 MP4 容器并不能保证播放兼容性。
- 兼容下载会检查成品编码；已经符合 H.264/AAC 要求的文件不会重复转码。

### 修复

- MP4 中的 VP9、AV1、非 AAC 音频和非 4:2:0 视频现在会通过 Apple VideoToolbox 转为 H.264、在存在音频时转为 AAC，并统一为 yuv420p。
- 兼容转换保留原下载文件名，并在完成前显示独立的中英文转换状态。

### 验证

- 新增编码探测、VP9 回归、转码参数和双语转换状态测试。
- 使用用户报告的 Instagram Reel 验证 VP9/yuv420p MP4 转为 H.264/yuv420p MP4；该源链接未提供音频流。
- 工具链和发布检查现已要求并实际执行 H.264 VideoToolbox 编码。

## [0.1.2] - 未发布

### 新增

- 主窗口、设置、菜单命令、格式表、状态和错误提示支持持久化、即时切换简体中文与 English。

### 修复

- SwiftPM 开发可执行文件或旧本地 APP 缺少内嵌资源时，工具定位会继续回退到仓库工具目录。
- 缺少组件提示现在能够区分不完整 APP 副本和当前正式打包产物，并给出对应恢复方式。

### 验证

- 新增工具目录回退和双语状态保持测试。
- 在中文界面完成真实本地 DASH 解析，保留解析结果切换至英文，并确认下载控件和格式列全部同步更新。

## [0.1.1] - 开发基线

### 变更

- 将 macOS 应用重构为与 ReadyType 风格统一的中文单任务下载工作台。
- 用链接、下载设置、可用画质和当前状态四个清晰区域替代占满窗口的空格式表格流程。
- 新增链接即时校验、旧解析结果清理、常见错误中文指引，以及更明确的加载、取消、成功和失败状态。
- 完成 macOS 设置窗口、菜单命令、格式表格、目录选择、下载方式和工具错误的中文化。

### 验证

- 新增链接校验、登录限制提示和旧状态清理测试。
- 验证真实 App 的无效/有效链接状态、模式切换、中文设置窗口和本地 DASH 格式解析。
- 重新验证真实 yt-dlp 最高画质下载和 FFmpeg 音视频合并流程。

### 新增

- 开源仓库政策和中英文项目文档。
- v0.1.0 双平台需求、架构、计划和发布检查文档。
- 原生 SwiftUI macOS 工程基础，包括设置窗口、工具链定位、可取消的 yt-dlp 格式查询和格式表格。
- Swift 格式解析测试和项目本地的 macOS 构建运行入口。
- 用于双平台解析一致性验证的共享脱敏 yt-dlp JSON fixture。
- 以 Mac 为主的下载流程，包括不限制分辨率的最佳画质、兼容 MP4 和手动格式模式。
- 实时进度、取消、持久保存目录书签和 Finder 定位。
- 当安全范围书签无法恢复时，为非沙盒开发版和 GitHub 发行版提供可靠的保存目录路径回退。
- 默认隐藏原始 yt-dlp 输出、可由用户主动开启的详细日志设置。
- 使用本地生成的 DASH 独立音视频流、真实 yt-dlp 进程和内嵌 FFmpeg 完成下载与合并集成验证。
- 固定 macOS arm64 工具链输入、SHA-256 校验以及基于 FFmpeg 官方源码的构建流程。
- 可复现的 APP、ZIP、DMG 打包，包括内嵌代码签名、可选公证、产物审计和校验文件。
- macOS Pull Request CI，以及需要发布凭据并由 Tag 驱动的 GitHub Release 工作流。
- 针对私密数据、凭据、媒体和旧产物的仓库及发布包禁止项扫描。
- 原创双平台品牌图形和可复现的 macOS `.icns` 生成流程。
- 基于固定 yt-dlp 提取器快照的版本化支持站点边界说明。

### 安全

- 将 Cookie、下载媒体、工具二进制、IDE 状态和构建产物排除在 Git 之外。

## [0.1.0] - 开发基线

- 计划中的首个公开版本，支持 Windows x64 和 macOS Apple Silicon。

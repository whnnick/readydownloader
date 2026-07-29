# 0.1.0 技术架构

## 架构决定

使用平台原生客户端和共享行为契约，不引入跨平台 UI 框架。

- Windows 保持 C++17 和 Win32。
- macOS 使用 Swift 6 和 SwiftUI。
- 两端共享产品需求、yt-dlp 参数规则、JSON fixtures、工具清单、发布版本和黑盒验收标准。

macOS 是主产品和主发布平台。Windows 是兼容实现，在 Mac 里程碑验证后按共享契约跟进；Windows 工作不阻塞 Mac 发布节奏。

这样既能保留现有 Windows 投入，也能让 macOS 直接使用 `Process`、`Pipe`、`JSONDecoder`、Swift Concurrency、Finder 集成和 security-scoped 文件访问。

## 目标仓库结构

```text
apps/windows/       Windows 应用和测试
apps/macos/         Swift Package、应用和测试
fixtures/yt-dlp/    脱敏的共享 JSON fixtures
scripts/            构建、验证和打包入口
docs/versions/      版本化需求和发布证据
.github/             CI、发布工作流和协作模板
```

只有建立可验证的 Windows 构建基线后，才把 Windows 工程移动到 `apps/windows/`。目录迁移不能和行为修改混在同一个提交中。

## 共享行为契约

两个平台都要实现等价操作：

```text
checkToolchain()
queryFormats(url, network, cookies)
download(url, selection, destination, network, cookies)
cancel(operation)
```

格式筛选和展示必须通过同一组脱敏 fixture 期望验证。进程启动、路径、UI 状态、文件选择和在文件管理器中显示由平台代码负责。

## macOS 组件

- `YouTubeDlpDownloaderApp`：`WindowGroup` 主入口和独立 `Settings` 场景。
- `DownloadStore`：在主线程管理链接、格式、选择、进度和错误状态。
- `YtDlpClient`：使用 actor 管理子进程生命周期和取消。
- `FormatParser`：解码和过滤 yt-dlp JSON。
- `ToolchainResolver`：定位并校验开发或发布工具链。
- `DownloadDirectoryStore`：保存 security-scoped bookmark。

`v0.1.0` 通过 GitHub Releases 直接分发，不进入 Mac App Store。本地 Debug 构建不要求公证；稳定发布应先签名嵌套工具，再使用 hardened runtime 签名主应用，完成公证并 stapling。

## Windows 组件

- Win32 UI 负责控件和窗口消息。
- 在进一步拆分前，`YtDlpService` 负责工具参数、进程执行、格式解析和错误映射。
- 发布版本不接受脱离生命周期管理的 UI 后台线程；任务必须可以等待或取消。

## 工具链分发

源码仓库只保存版本清单。打包脚本下载对应平台产物、校验 SHA-256、复制许可证，然后组装发布包。构建公开包时不得使用未锁定版本的工具。

## 版本管理

根目录 `VERSION` 是唯一版本来源。发布前必须验证平台清单、徽章、更新日志、Git tag、压缩包名称和 Release Notes 与它一致。

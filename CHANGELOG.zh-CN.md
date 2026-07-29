# 更新日志

本文件记录项目的重要变更。

格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本采用[语义化版本](https://semver.org/lang/zh-CN/)。

## [未发布]

### 新增

- 开源仓库政策和中英文项目文档。
- v0.1.0 双平台需求、架构、计划和发布检查文档。
- 原生 SwiftUI macOS 工程基础，包括设置窗口、工具链定位、可取消的 yt-dlp 格式查询和格式表格。
- Swift 格式解析测试和项目本地的 macOS 构建运行入口。
- 以 Mac 为主的下载流程，包括不限制分辨率的最佳画质、兼容 MP4 和手动格式模式。
- 实时进度、取消、持久保存目录书签和 Finder 定位。
- 使用本地生成测试视频和真实 yt-dlp 进程完成集成验证。
- 固定 macOS arm64 工具链输入、SHA-256 校验以及基于 FFmpeg 官方源码的构建流程。
- 可复现的 APP、ZIP、DMG 打包，包括内嵌代码签名、可选公证、产物审计和校验文件。
- macOS Pull Request CI，以及需要发布凭据并由 Tag 驱动的 GitHub Release 工作流。
- 针对私密数据、凭据、媒体和旧产物的仓库及发布包禁止项扫描。

### 安全

- 将 Cookie、下载媒体、工具二进制、IDE 状态和构建产物排除在 Git 之外。

## [0.1.0] - 未发布

- 计划中的首个公开版本，支持 Windows x64 和 macOS Apple Silicon。

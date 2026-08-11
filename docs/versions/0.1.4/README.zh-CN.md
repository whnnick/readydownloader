# ReadyDownloader 0.1.4

`0.1.4` 完成从继承项目名称到 ReadyDownloader 的产品重命名，并确定稳定的 GitHub 与 ReadySuite 集成标识。

本版本同时将 Mac 主产品线扩展到 macOS 13 及以上的 Apple Silicon Mac，并保持 Swift 5.10 及更新工具链可构建。

## 命名约束

- 产品与应用名称：`ReadyDownloader`
- GitHub 仓库：`whnnick/readydownloader`
- macOS Bundle ID：`com.readydownloader.app`
- macOS 与 Windows 可执行文件名：`ReadyDownloader`
- 发布产物前缀：`ReadyDownloader-<version>-macos-arm64`
- 未来 ReadySuite 产品标识和路由：`readydownloader`、`/readydownloader`
- 未来 ReadySuite 下载入口：`https://github.com/whnnick/readydownloader/releases/latest`

## 兼容性约束

- 最低运行系统：macOS 13.0
- Swift Package 工具版本：Swift 5.10
- 状态模型：Combine `ObservableObject`，不依赖 macOS 14 Observation
- 测试框架：Swift 5.10 工具链自带的 XCTest

## 验收入口

- [0.1.4 黑盒功能检查](./BLACK_BOX_TESTS.zh-CN.md)
- [0.1.3 iPhone 兼容媒体基线](../0.1.3/README.zh-CN.md)
- [发布流程](../../RELEASE.zh-CN.md)

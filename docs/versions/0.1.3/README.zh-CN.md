# YouTubeDlpDownloader 0.1.3

`0.1.3` 让 macOS 的“iPhone 兼容”模式执行明确的媒体编码约束，不再只依赖 `.mp4` 文件扩展名判断兼容性。

## 版本目标

- “最高画质”保持原样且不限制分辨率。
- 优先使用已有 H.264/AAC 源，并在下载完成后通过 FFprobe 检查成品。
- 使用 Apple VideoToolbox 将不兼容视频转为 H.264/yuv420p，在存在音频时转为 AAC。
- 保留下载文件名，并在处理期间显示中英文兼容转换状态。
- 要求发布包内 FFmpeg 提供并实际执行 H.264 VideoToolbox 编码器。

## 验收入口

- [0.1.3 黑盒功能检查](./BLACK_BOX_TESTS.zh-CN.md)
- [0.1.2 双语界面基线](../0.1.2/README.zh-CN.md)
- [发布流程](../../RELEASE.zh-CN.md)

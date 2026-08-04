enum DownloadStatusState: Equatable, Sendable {
    case ready
    case waitingForQuery(hasURL: Bool)
    case invalidURL
    case checkingTools
    case missingTools([String])
    case querying
    case noFormats
    case queryComplete(Int)
    case queryCancelled
    case queryFailed(String)
    case queryRequired
    case formatRequired
    case preparingDownload(String)
    case downloading(DownloadProgress)
    case downloadComplete(fileName: String?, directoryPath: String)
    case downloadCancelled
    case downloadFailed(String)
    case operationCancelled

    var kind: DownloadStatusKind {
        switch self {
        case .checkingTools, .querying, .preparingDownload, .downloading:
            .progress
        case .queryComplete, .downloadComplete:
            .success
        case .invalidURL, .missingTools, .noFormats, .queryFailed, .queryRequired,
             .formatRequired, .downloadFailed:
            .failure
        case .ready, .waitingForQuery, .queryCancelled, .downloadCancelled, .operationCancelled:
            .neutral
        }
    }

    func title(language: AppLanguage) -> String {
        switch self {
        case .ready: language.text("准备就绪", "Ready")
        case .waitingForQuery: language.text("等待解析", "Ready to Query")
        case .invalidURL: language.text("链接无效", "Invalid URL")
        case .checkingTools: language.text("正在检查运行组件", "Checking Components")
        case .missingTools: language.text("缺少运行组件", "Missing Components")
        case .querying: language.text("正在解析视频", "Querying Video")
        case .noFormats: language.text("没有找到可下载格式", "No Downloadable Formats")
        case .queryComplete: language.text("视频解析完成", "Video Ready")
        case .queryCancelled: language.text("已取消解析", "Query Cancelled")
        case .queryFailed: language.text("解析失败", "Query Failed")
        case .queryRequired: language.text("请先解析链接", "Query the URL First")
        case .formatRequired: language.text("请选择一个格式", "Select a Format")
        case .preparingDownload: language.text("正在准备下载", "Preparing Download")
        case .downloading(let progress):
            language.text("正在下载 \(progress.percentText)", "Downloading \(progress.percentText)")
        case .downloadComplete: language.text("下载完成", "Download Complete")
        case .downloadCancelled: language.text("下载已取消", "Download Cancelled")
        case .downloadFailed: language.text("下载失败", "Download Failed")
        case .operationCancelled: language.text("操作已取消", "Operation Cancelled")
        }
    }

    func detail(language: AppLanguage) -> String {
        switch self {
        case .ready:
            return language.text("粘贴视频链接，解析后即可选择画质并下载。", "Paste a video URL, query it, then choose a quality and download.")
        case .waitingForQuery(let hasURL):
            return hasURL
                ? language.text("点击“解析链接”读取视频信息和可用画质。", "Click Query URL to load video details and formats.")
                : language.text("粘贴视频链接，解析后即可选择画质并下载。", "Paste a video URL, query it, then choose a quality and download.")
        case .invalidURL:
            return language.text("请输入完整的 http 或 https 视频链接。", "Enter a complete http or https video URL.")
        case .checkingTools:
            return language.text("确认 yt-dlp 和视频处理组件可以正常使用。", "Checking that yt-dlp and the media tools are available.")
        case .missingTools(let names):
            return language.text(
                "缺少：\(names.joined(separator: "、"))。请使用当前版本 DMG 或 ZIP 中的 APP；开发构建请先运行工具准备脚本。",
                "Missing: \(names.joined(separator: ", ")). Use the app from the current DMG or ZIP; for development builds, prepare the toolchain first."
            )
        case .querying:
            return language.text("部分平台需要十几秒，请保持网络连接。", "Some services can take several seconds. Keep the network connected.")
        case .noFormats:
            return language.text("该链接可能需要登录、Cookie，或暂不受支持。", "The URL may require login or cookies, or may not be supported.")
        case .queryComplete(let count):
            return language.text("已找到 \(count) 个视频格式，可以选择下载方式。", "Found \(count) video format(s). Choose a download mode.")
        case .queryCancelled:
            return language.text("可以修改链接后重新解析。", "Edit the URL and query again when ready.")
        case .queryFailed(let error):
            return DownloadStore.friendlyErrorMessage(for: error, language: language)
        case .queryRequired:
            return language.text("解析完成后才能开始下载，避免下载错误的内容。", "Query the URL before downloading so the selected content is current.")
        case .formatRequired:
            return language.text("使用指定格式时，需要在可用画质列表中选中一项。", "Selected Format mode requires a choice from the format table.")
        case .preparingDownload(let folder):
            return language.text("即将保存到 \(folder)。", "The file will be saved to \(folder).")
        case .downloading(let progress):
            return language.text(
                "速度 \(progress.speed) · 预计剩余 \(progress.eta)",
                "Speed \(progress.speed) · ETA \(progress.eta)"
            )
        case .downloadComplete(let fileName, let directoryPath):
            if let fileName {
                return language.text("已保存：\(fileName)", "Saved: \(fileName)")
            }
            return language.text(
                "文件已保存到 \(directoryPath)。",
                "The file was saved to \(directoryPath)."
            )
        case .downloadCancelled:
            return language.text("未完成的临时文件会由下载工具处理。", "The downloader will handle any incomplete temporary files.")
        case .downloadFailed(let error):
            return DownloadStore.friendlyErrorMessage(for: error, language: language)
        case .operationCancelled:
            return language.text("可以修改设置后重新开始。", "Adjust the settings and start again when ready.")
        }
    }
}

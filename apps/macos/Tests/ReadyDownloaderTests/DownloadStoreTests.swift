import Testing
@testable import ReadyDownloader

@Suite("Download store")
@MainActor
struct DownloadStoreTests {
    @Test("Hides raw tool output when detailed logs are disabled")
    func hidesRawToolOutput() {
        let store = DownloadStore()
        store.language = .simplifiedChinese

        store.handleDownloadOutput(
            "WARNING: raw yt-dlp diagnostic",
            includeDetailedLogs: false
        )

        #expect(store.detailedLog.isEmpty)
    }

    @Test("Shows raw tool output when detailed logs are enabled")
    func showsRawToolOutput() {
        let store = DownloadStore()
        store.language = .simplifiedChinese

        store.handleDownloadOutput(
            "WARNING: raw yt-dlp diagnostic",
            includeDetailedLogs: true
        )

        #expect(store.detailedLog == "WARNING: raw yt-dlp diagnostic")
    }

    @Test("Progress remains visible when detailed logs are disabled")
    func keepsProgressVisible() {
        let store = DownloadStore()
        store.language = .simplifiedChinese

        store.handleDownloadOutput(
            "download:50.0%|1.0MiB/s|00:05",
            includeDetailedLogs: false
        )

        #expect(store.progress?.fractionCompleted == 0.5)
        #expect(store.status == "正在下载 50.0%")
        #expect(store.statusDetail == "速度 1.0MiB/s · 预计剩余 00:05")
        #expect(store.statusKind == .progress)
        #expect(store.detailedLog.isEmpty)
    }

    @Test("Hides raw failure details when detailed logs are disabled")
    func hidesRawFailureDetails() {
        let store = DownloadStore()
        store.language = .simplifiedChinese

        store.handleOperationFailure(
            operation: .download,
            errorDescription: "raw yt-dlp failure",
            includeDetailedLogs: false
        )

        #expect(store.status == "下载失败")
        #expect(store.statusKind == .failure)
        #expect(store.detailedLog.isEmpty)
    }

    @Test("Shows raw failure details when detailed logs are enabled")
    func showsRawFailureDetails() {
        let store = DownloadStore()
        store.language = .simplifiedChinese

        store.handleOperationFailure(
            operation: .download,
            errorDescription: "raw yt-dlp failure",
            includeDetailedLogs: true
        )

        #expect(store.status == "下载失败")
        #expect(store.detailedLog == "raw yt-dlp failure")
    }

    @Test("只接受完整的 HTTP 或 HTTPS 链接")
    func validatesMediaURL() {
        #expect(DownloadStore.isValidMediaURL("https://www.instagram.com/reel/example/"))
        #expect(DownloadStore.isValidMediaURL("http://example.com/video"))
        #expect(!DownloadStore.isValidMediaURL("www.instagram.com/reel/example"))
        #expect(!DownloadStore.isValidMediaURL("file:///tmp/video.mp4"))
        #expect(!DownloadStore.isValidMediaURL(""))
    }

    @Test("登录限制会显示可操作的中文提示")
    func mapsAuthenticationFailure() {
        let message = DownloadStore.friendlyErrorMessage(
            for: "Login required. Use --cookies to authenticate"
        )

        #expect(message.contains("Cookie"))
        #expect(message.contains("设置"))
    }

    @Test("链接变化会清理旧的下载状态")
    func resetsStateForChangedURL() {
        let store = DownloadStore()
        store.language = .simplifiedChinese
        store.urlText = "https://example.com/video"
        store.urlDidChange()

        #expect(store.status == "等待解析")
        #expect(store.statusDetail.contains("解析链接"))
        #expect(!store.canDownload)
    }

    @Test("切换语言会保留状态并即时更新文案")
    func switchesLanguageWithoutLosingState() {
        let store = DownloadStore()
        store.statusState = .queryComplete(3)
        store.language = .simplifiedChinese
        #expect(store.status == "视频解析完成")
        #expect(store.statusDetail.contains("3 个"))

        store.language = .english
        #expect(store.status == "Video Ready")
        #expect(store.statusDetail.contains("3 video"))
        #expect(store.statusState == .queryComplete(3))
    }

    @Test("下载完成详情会跟随语言切换")
    func localizesCompletedDownload() {
        let store = DownloadStore()
        store.statusState = .downloadComplete(
            fileName: "example.mp4",
            directoryPath: "/tmp"
        )

        store.language = .simplifiedChinese
        #expect(store.statusDetail == "已保存：example.mp4")
        store.language = .english
        #expect(store.statusDetail == "Saved: example.mp4")
    }

    @Test("兼容转码状态支持中英文切换")
    func localizesCompatibilityConversion() {
        let store = DownloadStore()
        store.statusState = .makingIPhoneCompatible

        store.language = .simplifiedChinese
        #expect(store.status == "正在优化 iPhone 兼容性")
        #expect(store.statusDetail.contains("H.264"))

        store.language = .english
        #expect(store.status == "Optimizing for iPhone")
        #expect(store.statusDetail.contains("H.264"))
    }

    @Test("缺少工具提示会指导用户使用完整发布包")
    func explainsMissingTools() {
        let state = DownloadStatusState.missingTools(["yt-dlp", "deno"])

        #expect(state.detail(language: .simplifiedChinese).contains("DMG 或 ZIP"))
        #expect(state.detail(language: .english).contains("DMG or ZIP"))
    }
}

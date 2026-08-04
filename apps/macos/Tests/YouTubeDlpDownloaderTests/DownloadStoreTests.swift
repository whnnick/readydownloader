import Testing
@testable import YouTubeDlpDownloader

@Suite("Download store")
@MainActor
struct DownloadStoreTests {
    @Test("Hides raw tool output when detailed logs are disabled")
    func hidesRawToolOutput() {
        let store = DownloadStore()

        store.handleDownloadOutput(
            "WARNING: raw yt-dlp diagnostic",
            includeDetailedLogs: false
        )

        #expect(store.detailedLog.isEmpty)
    }

    @Test("Shows raw tool output when detailed logs are enabled")
    func showsRawToolOutput() {
        let store = DownloadStore()

        store.handleDownloadOutput(
            "WARNING: raw yt-dlp diagnostic",
            includeDetailedLogs: true
        )

        #expect(store.detailedLog == "WARNING: raw yt-dlp diagnostic")
    }

    @Test("Progress remains visible when detailed logs are disabled")
    func keepsProgressVisible() {
        let store = DownloadStore()

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

        store.handleOperationFailure(
            status: "下载失败",
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

        store.handleOperationFailure(
            status: "下载失败",
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
        store.urlText = "https://example.com/video"
        store.urlDidChange()

        #expect(store.status == "等待解析")
        #expect(store.statusDetail.contains("解析链接"))
        #expect(!store.canDownload)
    }
}

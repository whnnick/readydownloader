import XCTest
@testable import ReadyDownloader

@MainActor
final class DownloadStoreTests: XCTestCase {
    func testHidesRawToolOutput() {
        let store = DownloadStore()
        store.language = .simplifiedChinese

        store.handleDownloadOutput(
            "WARNING: raw yt-dlp diagnostic",
            includeDetailedLogs: false
        )

        XCTAssertTrue(store.detailedLog.isEmpty)
    }

    func testShowsRawToolOutput() {
        let store = DownloadStore()
        store.language = .simplifiedChinese

        store.handleDownloadOutput(
            "WARNING: raw yt-dlp diagnostic",
            includeDetailedLogs: true
        )

        XCTAssertEqual(store.detailedLog, "WARNING: raw yt-dlp diagnostic")
    }

    func testKeepsProgressVisible() {
        let store = DownloadStore()
        store.language = .simplifiedChinese

        store.handleDownloadOutput(
            "download:50.0%|1.0MiB/s|00:05",
            includeDetailedLogs: false
        )

        XCTAssertEqual(store.progress?.fractionCompleted, 0.5)
        XCTAssertEqual(store.status, "正在下载 50.0%")
        XCTAssertEqual(store.statusDetail, "速度 1.0MiB/s · 预计剩余 00:05")
        XCTAssertEqual(store.statusKind, .progress)
        XCTAssertTrue(store.detailedLog.isEmpty)
    }

    func testHidesRawFailureDetails() {
        let store = DownloadStore()
        store.language = .simplifiedChinese

        store.handleOperationFailure(
            operation: .download,
            errorDescription: "raw yt-dlp failure",
            includeDetailedLogs: false
        )

        XCTAssertEqual(store.status, "下载失败")
        XCTAssertEqual(store.statusKind, .failure)
        XCTAssertTrue(store.detailedLog.isEmpty)
    }

    func testShowsRawFailureDetails() {
        let store = DownloadStore()
        store.language = .simplifiedChinese

        store.handleOperationFailure(
            operation: .download,
            errorDescription: "raw yt-dlp failure",
            includeDetailedLogs: true
        )

        XCTAssertEqual(store.status, "下载失败")
        XCTAssertEqual(store.detailedLog, "raw yt-dlp failure")
    }

    func testValidatesMediaURL() {
        XCTAssertTrue(DownloadStore.isValidMediaURL("https://www.instagram.com/reel/example/"))
        XCTAssertTrue(DownloadStore.isValidMediaURL("http://example.com/video"))
        XCTAssertFalse(DownloadStore.isValidMediaURL("www.instagram.com/reel/example"))
        XCTAssertFalse(DownloadStore.isValidMediaURL("file:///tmp/video.mp4"))
        XCTAssertFalse(DownloadStore.isValidMediaURL(""))
    }

    func testMapsAuthenticationFailure() {
        let message = DownloadStore.friendlyErrorMessage(
            for: "Login required. Use --cookies to authenticate"
        )

        XCTAssertTrue(message.contains("Cookie"))
        XCTAssertTrue(message.contains("设置"))
    }

    func testResetsStateForChangedURL() {
        let store = DownloadStore()
        store.language = .simplifiedChinese
        store.urlText = "https://example.com/video"
        store.urlDidChange()

        XCTAssertEqual(store.status, "等待解析")
        XCTAssertTrue(store.statusDetail.contains("解析链接"))
        XCTAssertFalse(store.canDownload)
    }

    func testSwitchesLanguageWithoutLosingState() {
        let store = DownloadStore()
        store.statusState = .queryComplete(3)
        store.language = .simplifiedChinese
        XCTAssertEqual(store.status, "视频解析完成")
        XCTAssertTrue(store.statusDetail.contains("3 个"))

        store.language = .english
        XCTAssertEqual(store.status, "Video Ready")
        XCTAssertTrue(store.statusDetail.contains("3 video"))
        XCTAssertEqual(store.statusState, .queryComplete(3))
    }

    func testLocalizesCompletedDownload() {
        let store = DownloadStore()
        store.statusState = .downloadComplete(
            fileName: "example.mp4",
            directoryPath: "/tmp"
        )

        store.language = .simplifiedChinese
        XCTAssertEqual(store.statusDetail, "已保存：example.mp4")
        store.language = .english
        XCTAssertEqual(store.statusDetail, "Saved: example.mp4")
    }

    func testLocalizesCompatibilityConversion() {
        let store = DownloadStore()
        store.statusState = .makingIPhoneCompatible

        store.language = .simplifiedChinese
        XCTAssertEqual(store.status, "正在优化 iPhone 兼容性")
        XCTAssertTrue(store.statusDetail.contains("H.264"))

        store.language = .english
        XCTAssertEqual(store.status, "Optimizing for iPhone")
        XCTAssertTrue(store.statusDetail.contains("H.264"))
    }

    func testExplainsMissingTools() {
        let state = DownloadStatusState.missingTools(["yt-dlp", "deno"])

        XCTAssertTrue(state.detail(language: .simplifiedChinese).contains("DMG 或 ZIP"))
        XCTAssertTrue(state.detail(language: .english).contains("DMG or ZIP"))
    }
}

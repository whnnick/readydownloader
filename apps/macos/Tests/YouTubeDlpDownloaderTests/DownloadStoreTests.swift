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
        #expect(store.status == "Downloading 50.0% · 1.0MiB/s · ETA 00:05")
        #expect(store.detailedLog.isEmpty)
    }

    @Test("Hides raw failure details when detailed logs are disabled")
    func hidesRawFailureDetails() {
        let store = DownloadStore()

        store.handleOperationFailure(
            status: "Download failed.",
            errorDescription: "raw yt-dlp failure",
            includeDetailedLogs: false
        )

        #expect(store.status == "Download failed.")
        #expect(store.detailedLog.isEmpty)
    }

    @Test("Shows raw failure details when detailed logs are enabled")
    func showsRawFailureDetails() {
        let store = DownloadStore()

        store.handleOperationFailure(
            status: "Download failed.",
            errorDescription: "raw yt-dlp failure",
            includeDetailedLogs: true
        )

        #expect(store.status == "Download failed.")
        #expect(store.detailedLog == "raw yt-dlp failure")
    }
}

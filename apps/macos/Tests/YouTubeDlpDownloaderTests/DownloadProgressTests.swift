import Testing
@testable import YouTubeDlpDownloader

@Suite("Download progress")
struct DownloadProgressTests {
    @Test("Template emits a parseable download prefix")
    func templateIncludesLiteralPrefix() {
        #expect(DownloadProgress.ytDlpTemplate.hasPrefix("download:download:"))
    }

    @Test("Parses yt-dlp progress template")
    func parsesProgress() throws {
        let progress = try #require(
            DownloadProgress.parse(line: "download: 42.5%| 8.2MiB/s|00:13")
        )
        #expect(progress.fractionCompleted == 0.425)
        #expect(progress.percentText == "42.5%")
        #expect(progress.speed == "8.2MiB/s")
        #expect(progress.eta == "00:13")
    }

    @Test("Rejects non-progress output")
    func rejectsOtherOutput() {
        #expect(DownloadProgress.parse(line: "[Merger] Merging formats") == nil)
    }
}

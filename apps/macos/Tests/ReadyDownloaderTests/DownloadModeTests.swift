import Testing
@testable import ReadyDownloader

@Suite("Download mode")
struct DownloadModeTests {
    @Test("Best quality has no resolution cap")
    func bestQualitySelector() throws {
        #expect(try DownloadMode.bestQuality.formatSelector(selectedFormat: nil) == "bv*+ba/b")
    }

    @Test("Compatible mode prefers H264 but keeps a best-quality fallback for transcoding")
    func compatibleMP4Selector() throws {
        #expect(
            try DownloadMode.compatibleMP4.formatSelector(selectedFormat: nil)
                == "bv[ext=mp4][vcodec^=avc1]+ba[ext=m4a]/b[ext=mp4][vcodec^=avc1]/bv*+ba/b"
        )
    }

    @Test("Manual video-only format adds best audio")
    func selectedVideoOnlyFormat() throws {
        let format = makeFormat(id: "315", audioCodec: "none")
        #expect(try DownloadMode.selectedFormat.formatSelector(selectedFormat: format) == "315+ba")
    }

    @Test("Manual combined format is not given duplicate audio")
    func selectedCombinedFormat() throws {
        let format = makeFormat(id: "22", audioCodec: "mp4a.40.2")
        #expect(try DownloadMode.selectedFormat.formatSelector(selectedFormat: format) == "22")
    }

    @Test("Manual mode requires a selected format")
    func missingSelectedFormat() {
        #expect(throws: DownloadRequestError.self) {
            try DownloadMode.selectedFormat.formatSelector(selectedFormat: nil)
        }
    }

    private func makeFormat(id: String, audioCodec: String) -> YtDlpFormat {
        YtDlpFormat(
            id: id,
            ext: "mp4",
            resolution: "1920x1080",
            width: 1920,
            height: 1080,
            fps: 30,
            videoCodec: "avc1",
            audioCodec: audioCodec,
            fileSize: nil,
            totalBitrate: nil
        )
    }
}

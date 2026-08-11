import XCTest
@testable import ReadyDownloader

final class DownloadModeTests: XCTestCase {
    func testBestQualitySelector() throws {
        XCTAssertEqual(try DownloadMode.bestQuality.formatSelector(selectedFormat: nil), "bv*+ba/b")
    }

    func testCompatibleMP4Selector() throws {
        XCTAssertEqual(
            try DownloadMode.compatibleMP4.formatSelector(selectedFormat: nil),
            "bv[ext=mp4][vcodec^=avc1]+ba[ext=m4a]/b[ext=mp4][vcodec^=avc1]/bv*+ba/b"
        )
    }

    func testSelectedVideoOnlyFormat() throws {
        let format = makeFormat(id: "315", audioCodec: "none")
        XCTAssertEqual(try DownloadMode.selectedFormat.formatSelector(selectedFormat: format), "315+ba")
    }

    func testSelectedCombinedFormat() throws {
        let format = makeFormat(id: "22", audioCodec: "mp4a.40.2")
        XCTAssertEqual(try DownloadMode.selectedFormat.formatSelector(selectedFormat: format), "22")
    }

    func testMissingSelectedFormat() {
        XCTAssertThrowsError(
            try DownloadMode.selectedFormat.formatSelector(selectedFormat: nil)
        ) { error in
            XCTAssertTrue(error is DownloadRequestError)
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

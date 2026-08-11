import XCTest
@testable import ReadyDownloader

final class DownloadProgressTests: XCTestCase {
    func testTemplateIncludesLiteralPrefix() {
        XCTAssertTrue(DownloadProgress.ytDlpTemplate.hasPrefix("download:download:"))
    }

    func testParsesProgress() throws {
        let progress = try XCTUnwrap(
            DownloadProgress.parse(line: "download: 42.5%| 8.2MiB/s|00:13")
        )
        XCTAssertEqual(progress.fractionCompleted, 0.425)
        XCTAssertEqual(progress.percentText, "42.5%")
        XCTAssertEqual(progress.speed, "8.2MiB/s")
        XCTAssertEqual(progress.eta, "00:13")
    }

    func testRejectsOtherOutput() {
        XCTAssertNil(DownloadProgress.parse(line: "[Merger] Merging formats"))
    }
}

import Foundation
import XCTest
@testable import ReadyDownloader

final class FormatParserTests: XCTestCase {
    func testFiltersUnsupportedFormats() throws {
        let formats = try FormatParser.parse(fixtureData())
        XCTAssertEqual(formats.map(\.id), ["315", "137", "22"])
        XCTAssertEqual(formats[0].resolution, "3840x2160")
        XCTAssertTrue(formats[0].isVideoOnly)
        XCTAssertFalse(formats[2].isVideoOnly)
    }

    func testApproximateSizeFallback() throws {
        let formats = try FormatParser.parse(fixtureData())
        let format = try XCTUnwrap(formats.first { $0.id == "137" })
        XCTAssertEqual(format.fileSize, 12_345_678)
        XCTAssertEqual(format.displayBitrate, "4500k")
    }

    private func fixtureData() throws -> Data {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let fixtureURL = repositoryRoot
            .appendingPathComponent("fixtures/yt-dlp/formats-single-video.json")
        return try Data(contentsOf: fixtureURL)
    }
}

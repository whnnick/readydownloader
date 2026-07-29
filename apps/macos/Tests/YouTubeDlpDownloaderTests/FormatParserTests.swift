import Foundation
import Testing
@testable import YouTubeDlpDownloader

@Suite("Format parser")
struct FormatParserTests {
    @Test("Filters non-video and storyboard entries")
    func filtersUnsupportedFormats() throws {
        let formats = try FormatParser.parse(fixtureData())
        #expect(formats.map(\.id) == ["315", "137", "22"])
        #expect(formats[0].resolution == "3840x2160")
        #expect(formats[0].isVideoOnly)
        #expect(!formats[2].isVideoOnly)
    }

    @Test("Uses approximate size when exact size is absent")
    func approximateSizeFallback() throws {
        let formats = try FormatParser.parse(fixtureData())
        let format = try #require(formats.first { $0.id == "137" })
        #expect(format.fileSize == 12_345_678)
        #expect(format.displayBitrate == "4500k")
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

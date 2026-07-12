import Foundation
import Testing
@testable import YouTubeDlpDownloader

@Suite("Format parser")
struct FormatParserTests {
    @Test("Filters non-video and storyboard entries")
    func filtersUnsupportedFormats() throws {
        let formats = try FormatParser.parse(Data(fixture.utf8))
        #expect(formats.map(\.id) == ["315", "137", "22"])
        #expect(formats[0].resolution == "3840x2160")
        #expect(formats[0].isVideoOnly)
        #expect(!formats[2].isVideoOnly)
    }

    @Test("Uses approximate size when exact size is absent")
    func approximateSizeFallback() throws {
        let formats = try FormatParser.parse(Data(fixture.utf8))
        let format = try #require(formats.first { $0.id == "137" })
        #expect(format.fileSize == 12_345_678)
        #expect(format.displayBitrate == "4500k")
    }

    private let fixture = """
    {
      "formats": [
        {"format_id":"140","ext":"m4a","acodec":"mp4a.40.2","vcodec":"none","filesize":1000},
        {"format_id":"sb0","ext":"mhtml","width":160,"height":90,"vcodec":"images","acodec":"none"},
        {"format_id":"22","ext":"mp4","width":1280,"height":720,"fps":30,"vcodec":"avc1","acodec":"mp4a.40.2","filesize":5000000,"tbr":1500},
        {"format_id":"137","ext":"mp4","width":1920,"height":1080,"fps":30,"vcodec":"avc1","acodec":"none","filesize_approx":12345678,"tbr":4500},
        {"format_id":"315","ext":"webm","width":3840,"height":2160,"fps":60,"vcodec":"vp9","acodec":"none","filesize":50000000,"tbr":12000}
      ]
    }
    """
}

import Foundation
import XCTest
@testable import ReadyDownloader

final class CompatibleMediaTests: XCTestCase {
    func testAcceptsCompatibleMP4() throws {
        let data = Data(
            """
            {
              "streams": [
                {"codec_type":"video","codec_name":"h264","pix_fmt":"yuv420p"},
                {"codec_type":"audio","codec_name":"aac"}
              ],
              "format":{"format_name":"mov,mp4,m4a,3gp,3g2,mj2"}
            }
            """.utf8
        )

        XCTAssertTrue(try CompatibleMedia.isIPhoneCompatible(probeData: data))
    }

    func testRejectsVP9MP4() throws {
        let data = Data(
            """
            {
              "streams": [
                {"codec_type":"video","codec_name":"vp9","pix_fmt":"yuv420p"},
                {"codec_type":"audio","codec_name":"aac"}
              ],
              "format":{"format_name":"mov,mp4,m4a,3gp,3g2,mj2"}
            }
            """.utf8
        )

        XCTAssertFalse(try CompatibleMedia.isIPhoneCompatible(probeData: data))
    }

    func testRejectsIncompatibleStreams() throws {
        let nonAAC = Data(
            """
            {
              "streams": [
                {"codec_type":"video","codec_name":"h264","pix_fmt":"yuv420p"},
                {"codec_type":"audio","codec_name":"opus"}
              ],
              "format":{"format_name":"mp4"}
            }
            """.utf8
        )
        let non420 = Data(
            """
            {
              "streams": [
                {"codec_type":"video","codec_name":"h264","pix_fmt":"yuv444p"}
              ],
              "format":{"format_name":"mp4"}
            }
            """.utf8
        )

        XCTAssertFalse(try CompatibleMedia.isIPhoneCompatible(probeData: nonAAC))
        XCTAssertFalse(try CompatibleMedia.isIPhoneCompatible(probeData: non420))
    }

    func testTranscodeArguments() {
        let input = URL(filePath: "/tmp/source.mp4")
        let output = URL(filePath: "/tmp/output.mp4")
        let arguments = CompatibleMedia.transcodeArguments(input: input, output: output)

        XCTAssertTrue(arguments.contains("h264_videotoolbox"))
        XCTAssertTrue(arguments.contains("aac"))
        XCTAssertTrue(arguments.contains("scale=trunc(iw/2)*2:trunc(ih/2)*2,format=yuv420p"))
        XCTAssertTrue(arguments.contains("+faststart"))
        XCTAssertEqual(arguments.last, output.path)
    }
}

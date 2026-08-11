import Foundation
import Testing
@testable import YouTubeDlpDownloader

@Suite("iPhone-compatible media")
struct CompatibleMediaTests {
    @Test("Accepts H264, AAC, yuv420p MP4 without transcoding")
    func acceptsCompatibleMP4() throws {
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

        #expect(try CompatibleMedia.isIPhoneCompatible(probeData: data))
    }

    @Test("Rejects VP9 video inside an MP4 container")
    func rejectsVP9MP4() throws {
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

        #expect(!(try CompatibleMedia.isIPhoneCompatible(probeData: data)))
    }

    @Test("Rejects non-AAC audio and non-420 pixel formats")
    func rejectsIncompatibleStreams() throws {
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

        #expect(!(try CompatibleMedia.isIPhoneCompatible(probeData: nonAAC)))
        #expect(!(try CompatibleMedia.isIPhoneCompatible(probeData: non420)))
    }

    @Test("Transcode arguments force broadly compatible codecs and layout")
    func transcodeArguments() {
        let input = URL(filePath: "/tmp/source.mp4")
        let output = URL(filePath: "/tmp/output.mp4")
        let arguments = CompatibleMedia.transcodeArguments(input: input, output: output)

        #expect(arguments.contains("h264_videotoolbox"))
        #expect(arguments.contains("aac"))
        #expect(arguments.contains("scale=trunc(iw/2)*2:trunc(ih/2)*2,format=yuv420p"))
        #expect(arguments.contains("+faststart"))
        #expect(arguments.last == output.path)
    }
}

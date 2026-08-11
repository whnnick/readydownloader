import Foundation

enum CompatibleMedia {
    static func isIPhoneCompatible(probeData: Data) throws -> Bool {
        let probe = try JSONDecoder().decode(MediaProbe.self, from: probeData)
        guard probe.format.formatName
            .lowercased()
            .split(separator: ",")
            .contains("mp4"),
              let video = probe.streams.first(where: { $0.codecType == "video" }),
              video.codecName.lowercased() == "h264",
              ["yuv420p", "yuvj420p"].contains(video.pixelFormat.lowercased()) else {
            return false
        }

        return probe.streams
            .filter { $0.codecType == "audio" }
            .allSatisfy { $0.codecName.lowercased() == "aac" }
    }

    static func probeArguments(file: URL) -> [String] {
        [
            "-v", "error",
            "-show_entries", "stream=codec_type,codec_name,pix_fmt:format=format_name",
            "-of", "json",
            file.path
        ]
    }

    static func transcodeArguments(input: URL, output: URL) -> [String] {
        [
            "-hide_banner", "-y",
            "-i", input.path,
            "-map", "0:v:0",
            "-map", "0:a:0?",
            "-map_metadata", "0",
            "-vf", "scale=trunc(iw/2)*2:trunc(ih/2)*2,format=yuv420p",
            "-c:v", "h264_videotoolbox",
            "-allow_sw", "1",
            "-q:v", "65",
            "-tag:v", "avc1",
            "-c:a", "aac",
            "-b:a", "192k",
            "-movflags", "+faststart",
            output.path
        ]
    }
}

private struct MediaProbe: Decodable {
    let streams: [MediaStream]
    let format: MediaFormat
}

private struct MediaStream: Decodable {
    let codecType: String
    let codecName: String
    let pixelFormat: String

    enum CodingKeys: String, CodingKey {
        case codecType = "codec_type"
        case codecName = "codec_name"
        case pixelFormat = "pix_fmt"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        codecType = try container.decodeIfPresent(String.self, forKey: .codecType) ?? ""
        codecName = try container.decodeIfPresent(String.self, forKey: .codecName) ?? ""
        pixelFormat = try container.decodeIfPresent(String.self, forKey: .pixelFormat) ?? ""
    }
}

private struct MediaFormat: Decodable {
    let formatName: String

    enum CodingKeys: String, CodingKey {
        case formatName = "format_name"
    }
}

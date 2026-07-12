import Foundation

enum FormatParser {
    static func parse(_ data: Data) throws -> [YtDlpFormat] {
        let response = try JSONDecoder().decode(VideoResponse.self, from: data)
        return response.formats.compactMap { raw in
            guard
                !raw.formatID.isEmpty,
                !raw.formatID.hasPrefix("sb"),
                let height = raw.height,
                height > 0,
                let videoCodec = raw.videoCodec,
                !videoCodec.isEmpty,
                videoCodec != "none"
            else { return nil }

            let resolution = raw.width.map { "\($0)x\(height)" } ?? "\(height)p"
            return YtDlpFormat(
                id: raw.formatID,
                ext: raw.ext ?? "—",
                resolution: resolution,
                width: raw.width,
                height: height,
                fps: raw.fps.map { Int($0.rounded()) },
                videoCodec: videoCodec,
                audioCodec: raw.audioCodec ?? "",
                fileSize: raw.fileSize ?? raw.approximateFileSize,
                totalBitrate: raw.totalBitrate
            )
        }
        .sorted(by: sortFormats)
    }

    private static func sortFormats(_ lhs: YtDlpFormat, _ rhs: YtDlpFormat) -> Bool {
        let leftPriority = resolutionPriority(lhs.height)
        let rightPriority = resolutionPriority(rhs.height)
        if leftPriority != rightPriority { return leftPriority < rightPriority }
        if lhs.height != rhs.height { return lhs.height > rhs.height }
        if lhs.fps != rhs.fps { return (lhs.fps ?? 0) > (rhs.fps ?? 0) }
        if lhs.ext != rhs.ext { return lhs.ext < rhs.ext }
        return lhs.id < rhs.id
    }

    private static func resolutionPriority(_ height: Int) -> Int {
        switch height {
        case 2160: 0
        case 1440: 1
        case 1080: 2
        case 720: 3
        default: 1000 - height
        }
    }
}

private struct VideoResponse: Decodable {
    let formats: [RawFormat]
}

private struct RawFormat: Decodable {
    let formatID: String
    let ext: String?
    let width: Int?
    let height: Int?
    let fps: Double?
    let videoCodec: String?
    let audioCodec: String?
    let fileSize: Double?
    let approximateFileSize: Double?
    let totalBitrate: Double?

    enum CodingKeys: String, CodingKey {
        case formatID = "format_id"
        case ext, width, height, fps
        case videoCodec = "vcodec"
        case audioCodec = "acodec"
        case fileSize = "filesize"
        case approximateFileSize = "filesize_approx"
        case totalBitrate = "tbr"
    }
}

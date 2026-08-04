import Foundation

struct YtDlpFormat: Identifiable, Hashable, Sendable {
    let id: String
    let ext: String
    let resolution: String
    let width: Int?
    let height: Int
    let fps: Int?
    let videoCodec: String
    let audioCodec: String
    let fileSize: Double?
    let totalBitrate: Double?

    var isVideoOnly: Bool { audioCodec.isEmpty || audioCodec == "none" }
    var displayFPS: String { fps.map(String.init) ?? "—" }
    var displayAudioCodec: String { isVideoOnly ? "仅视频" : audioCodec }

    var displayFileSize: String {
        guard let fileSize, fileSize > 0 else { return "—" }
        return ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
    }

    var displayBitrate: String {
        guard let totalBitrate, totalBitrate > 0 else { return "—" }
        return "\(Int(totalBitrate.rounded()))k"
    }
}

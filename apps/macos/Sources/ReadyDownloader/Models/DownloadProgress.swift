import Foundation

struct DownloadProgress: Equatable, Sendable {
    static let ytDlpTemplate = "download:download:%(progress._percent_str)s|%(progress._speed_str)s|%(progress._eta_str)s"

    let fractionCompleted: Double?
    let percentText: String
    let speed: String
    let eta: String

    static func parse(line: String) -> DownloadProgress? {
        guard line.hasPrefix("download:") else { return nil }
        let fields = line.dropFirst("download:".count).split(separator: "|", omittingEmptySubsequences: false)
        guard fields.count >= 3 else { return nil }

        let percentText = fields[0].trimmingCharacters(in: .whitespacesAndNewlines)
        let numberText = percentText.replacingOccurrences(of: "%", with: "")
        let percent = Double(numberText).map { min(max($0 / 100, 0), 1) }
        return DownloadProgress(
            fractionCompleted: percent,
            percentText: percentText,
            speed: fields[1].trimmingCharacters(in: .whitespacesAndNewlines),
            eta: fields[2].trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}

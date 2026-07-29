import Foundation

enum DownloadMode: String, CaseIterable, Identifiable, Sendable {
    case bestQuality
    case compatibleMP4
    case selectedFormat

    var id: Self { self }

    var title: String {
        switch self {
        case .bestQuality: "Best Quality"
        case .compatibleMP4: "Compatible MP4"
        case .selectedFormat: "Selected Format"
        }
    }

    func formatSelector(selectedFormat: YtDlpFormat?) throws -> String {
        switch self {
        case .bestQuality:
            return "bv*+ba/b"
        case .compatibleMP4:
            return "bv*[ext=mp4][vcodec^=avc1]+ba[ext=m4a]/b[ext=mp4]/b"
        case .selectedFormat:
            guard let selectedFormat else { throw DownloadRequestError.missingSelectedFormat }
            return selectedFormat.isVideoOnly ? "\(selectedFormat.id)+ba" : selectedFormat.id
        }
    }
}

enum DownloadRequestError: LocalizedError {
    case missingSelectedFormat

    var errorDescription: String? {
        switch self {
        case .missingSelectedFormat:
            "Select a format before using Selected Format mode."
        }
    }
}

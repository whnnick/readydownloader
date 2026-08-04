import Foundation

enum DownloadMode: String, CaseIterable, Identifiable, Sendable {
    case bestQuality
    case compatibleMP4
    case selectedFormat

    var id: Self { self }

    var title: String {
        switch self {
        case .bestQuality: "最高画质"
        case .compatibleMP4: "兼容 MP4"
        case .selectedFormat: "指定格式"
        }
    }

    var description: String {
        switch self {
        case .bestQuality: "自动下载该视频可用的最高画质，并在需要时合并音频。"
        case .compatibleMP4: "优先选择 H.264 视频和 M4A 音频，适合更多播放器。"
        case .selectedFormat: "使用下方列表中选中的格式；纯视频格式会自动补充音频。"
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
            "使用指定格式时，请先在格式列表中选择一项。"
        }
    }
}

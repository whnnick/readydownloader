import Foundation

enum DownloadMode: String, CaseIterable, Identifiable, Sendable {
    case bestQuality
    case compatibleMP4
    case selectedFormat

    var id: Self { self }

    func title(language: AppLanguage) -> String {
        switch self {
        case .bestQuality: language.text("最高画质", "Best Quality")
        case .compatibleMP4: language.text("iPhone 兼容", "iPhone Compatible")
        case .selectedFormat: language.text("指定格式", "Selected Format")
        }
    }

    func description(language: AppLanguage) -> String {
        switch self {
        case .bestQuality:
            language.text(
                "自动下载该视频可用的最高画质，并在需要时合并音频。",
                "Downloads the best available quality and merges audio when needed."
            )
        case .compatibleMP4:
            language.text(
                "下载后自动检查编码；需要时将视频转为 H.264，已有音频转为 AAC。",
                "Checks the finished file and converts video to H.264 and any available audio to AAC when needed."
            )
        case .selectedFormat:
            language.text(
                "使用下方列表中选中的格式；纯视频格式会自动补充音频。",
                "Uses the selected table format and adds audio to video-only streams."
            )
        }
    }

    func formatSelector(selectedFormat: YtDlpFormat?) throws -> String {
        switch self {
        case .bestQuality:
            return "bv*+ba/b"
        case .compatibleMP4:
            return "bv[ext=mp4][vcodec^=avc1]+ba[ext=m4a]/b[ext=mp4][vcodec^=avc1]/bv*+ba/b"
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
            AppLanguage.current.text(
                "使用指定格式时，请先在格式列表中选择一项。",
                "Select a format before using Selected Format mode."
            )
        }
    }
}

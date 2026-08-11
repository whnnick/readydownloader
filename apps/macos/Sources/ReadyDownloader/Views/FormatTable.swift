import SwiftUI

struct FormatTable: View {
    let formats: [YtDlpFormat]
    @Binding var selection: YtDlpFormat.ID?
    let isQuerying: Bool
    let hasURL: Bool
    @AppStorage(AppLanguage.storageKey) private var languageRawValue = AppLanguage.simplifiedChinese.rawValue

    private var language: AppLanguage {
        AppLanguage(rawValue: languageRawValue) ?? .simplifiedChinese
    }

    var body: some View {
        Table(formats, selection: $selection) {
            TableColumn(language.text("格式", "Format"), value: \.id).width(min: 60, ideal: 75)
            TableColumn(language.text("封装", "Container"), value: \.ext).width(min: 50, ideal: 60)
            TableColumn(language.text("分辨率", "Resolution"), value: \.resolution).width(min: 90, ideal: 110)
            TableColumn(language.text("帧率", "FPS"), value: \.displayFPS).width(min: 45, ideal: 55)
            TableColumn(language.text("视频编码", "Video Codec"), value: \.videoCodec).width(min: 120, ideal: 160)
            TableColumn(language.text("音频编码", "Audio Codec")) { format in
                Text(format.displayAudioCodec(language: language))
            }
            .width(min: 90, ideal: 110)
            TableColumn(language.text("大小", "Size"), value: \.displayFileSize).width(min: 75, ideal: 90)
            TableColumn(language.text("码率", "Bitrate"), value: \.displayBitrate).width(min: 60, ideal: 70)
        }
        .overlay {
            if formats.isEmpty {
                if isQuerying {
                    VStack(spacing: 10) {
                        ProgressView()
                        Text(language.text("正在读取视频信息…", "Loading video details…"))
                            .font(.callout.weight(.medium))
                        Text(language.text(
                            "部分平台的首次解析可能需要十几秒。",
                            "The first query for some services may take several seconds."
                        ))
                            .font(.footnote)
                            .foregroundStyle(DownloaderTheme.muted)
                    }
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: hasURL ? "sparkle.magnifyingglass" : "link")
                            .font(.system(size: 30, weight: .medium))
                            .foregroundStyle(DownloaderTheme.muted)
                        Text(
                            hasURL
                                ? language.text("等待解析", "Ready to Query")
                                : language.text("粘贴视频链接", "Paste a Video URL")
                        )
                        .font(.headline)
                        Text(
                            hasURL
                                ? language.text("点击“解析链接”查看可用画质。", "Click Query URL to view available formats.")
                                : language.text(
                                    "支持 YouTube、哔哩哔哩、Instagram 等 yt-dlp 可解析的平台。",
                                    "Supports YouTube, Bilibili, Instagram, and other services handled by yt-dlp."
                                )
                        )
                        .font(.footnote)
                        .foregroundStyle(DownloaderTheme.muted)
                    }
                    .multilineTextAlignment(.center)
                    .padding()
                }
            }
        }
    }
}

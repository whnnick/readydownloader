import SwiftUI

struct FormatTable: View {
    let formats: [YtDlpFormat]
    @Binding var selection: YtDlpFormat.ID?
    let isQuerying: Bool
    let hasURL: Bool

    var body: some View {
        Table(formats, selection: $selection) {
            TableColumn("格式", value: \.id).width(min: 60, ideal: 75)
            TableColumn("封装", value: \.ext).width(min: 50, ideal: 60)
            TableColumn("分辨率", value: \.resolution).width(min: 90, ideal: 110)
            TableColumn("帧率", value: \.displayFPS).width(min: 45, ideal: 55)
            TableColumn("视频编码", value: \.videoCodec).width(min: 120, ideal: 160)
            TableColumn("音频编码", value: \.displayAudioCodec).width(min: 90, ideal: 110)
            TableColumn("大小", value: \.displayFileSize).width(min: 75, ideal: 90)
            TableColumn("码率", value: \.displayBitrate).width(min: 60, ideal: 70)
        }
        .overlay {
            if formats.isEmpty {
                if isQuerying {
                    VStack(spacing: 10) {
                        ProgressView()
                        Text("正在读取视频信息…")
                            .font(.callout.weight(.medium))
                        Text("部分平台的首次解析可能需要十几秒。")
                            .font(.footnote)
                            .foregroundStyle(DownloaderTheme.muted)
                    }
                } else {
                    ContentUnavailableView(
                        hasURL ? "等待解析" : "粘贴视频链接",
                        systemImage: hasURL ? "sparkle.magnifyingglass" : "link",
                        description: Text(hasURL ? "点击“解析链接”查看可用画质。" : "支持 YouTube、哔哩哔哩、Instagram 等 yt-dlp 可解析的平台。")
                    )
                }
            }
        }
    }
}

import SwiftUI

struct FormatTable: View {
    let formats: [YtDlpFormat]
    @Binding var selection: YtDlpFormat.ID?

    var body: some View {
        Table(formats, selection: $selection) {
            TableColumn("Format", value: \.id).width(min: 70, ideal: 85)
            TableColumn("Type", value: \.ext).width(min: 55, ideal: 65)
            TableColumn("Resolution", value: \.resolution).width(min: 100, ideal: 120)
            TableColumn("FPS", value: \.displayFPS).width(min: 50, ideal: 60)
            TableColumn("Video Codec", value: \.videoCodec).width(min: 130, ideal: 180)
            TableColumn("Audio Codec", value: \.displayAudioCodec).width(min: 100, ideal: 130)
            TableColumn("Size", value: \.displayFileSize).width(min: 80, ideal: 100)
            TableColumn("Bitrate", value: \.displayBitrate).width(min: 65, ideal: 80)
        }
        .overlay {
            if formats.isEmpty {
                ContentUnavailableView(
                    "No Formats",
                    systemImage: "film.stack",
                    description: Text("Query a URL to inspect its available video formats.")
                )
            }
        }
    }
}

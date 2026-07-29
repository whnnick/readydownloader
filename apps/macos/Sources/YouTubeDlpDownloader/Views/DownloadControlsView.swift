import SwiftUI

struct DownloadControlsView: View {
    @Bindable var store: DownloadStore

    var body: some View {
        HStack(spacing: 12) {
            Picker("Download", selection: $store.downloadMode) {
                ForEach(DownloadMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .frame(width: 240)

            Divider().frame(height: 22)

            Image(systemName: "folder")
                .foregroundStyle(.secondary)
            Text(store.downloadDirectory.path)
                .lineLimit(1)
                .truncationMode(.middle)
                .help(store.downloadDirectory.path)
            Button("Choose…") { store.chooseDownloadDirectory() }
                .disabled(store.isWorking)

            Spacer()

            Button("Download") { store.download() }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut("d", modifiers: [.command])
                .disabled(!store.canDownload)
        }
    }
}

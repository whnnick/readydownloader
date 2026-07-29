import SwiftUI

struct ContentView: View {
    @Bindable var store: DownloadStore

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                TextField("Media URL", text: $store.urlText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(store.queryFormats)
                Button("Query Formats", action: store.queryFormats)
                    .keyboardShortcut(.return, modifiers: [.command])
                    .disabled(store.isWorking)
            }
            .padding()

            Divider()
            FormatTable(formats: store.formats, selection: $store.selectedFormatID)
            Divider()

            DownloadControlsView(store: store)
                .padding(.horizontal)
                .padding(.vertical, 10)
            Divider()

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    if store.isWorking { ProgressView().controlSize(.small) }
                    Text(store.status).foregroundStyle(.secondary)
                    Spacer()
                }
                if let progress = store.progress, let fraction = progress.fractionCompleted {
                    ProgressView(value: fraction)
                }
                if !store.detailedLog.isEmpty {
                    ScrollView {
                        Text(store.detailedLog)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 110)
                }
            }
            .padding()
        }
        .toolbar {
            ToolbarItemGroup {
                Button { store.queryFormats() } label: {
                    Label("Query Formats", systemImage: "arrow.clockwise")
                }
                .disabled(store.isWorking)
                Button { store.cancel() } label: {
                    Label("Cancel", systemImage: "xmark.circle")
                }
                .disabled(!store.isWorking)
                Button { store.download() } label: {
                    Label("Download", systemImage: "arrow.down.circle")
                }
                .disabled(!store.canDownload)
                Button { store.revealCompletedFile() } label: {
                    Label("Show in Finder", systemImage: "folder")
                }
                .disabled(store.completedFile == nil)
                SettingsLink { Label("Settings", systemImage: "gearshape") }
            }
        }
    }
}

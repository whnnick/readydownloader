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

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    if store.isWorking { ProgressView().controlSize(.small) }
                    Text(store.status).foregroundStyle(.secondary)
                    Spacer()
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
                SettingsLink { Label("Settings", systemImage: "gearshape") }
            }
        }
    }
}

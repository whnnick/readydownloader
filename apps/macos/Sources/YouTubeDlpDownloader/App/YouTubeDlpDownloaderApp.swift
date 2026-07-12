import SwiftUI

@main
struct YouTubeDlpDownloaderApp: App {
    @State private var store = DownloadStore()

    var body: some Scene {
        WindowGroup("YouTubeDlpDownloader", id: "main") {
            ContentView(store: store)
                .frame(minWidth: 980, minHeight: 640)
        }
        .defaultSize(width: 1180, height: 760)
        .commands {
            CommandGroup(after: .newItem) {
                Button("Query Formats") { store.queryFormats() }
                    .keyboardShortcut(.return, modifiers: [.command])
                    .disabled(store.isWorking)
                Button("Cancel Current Operation") { store.cancel() }
                    .keyboardShortcut(.escape, modifiers: [])
                    .disabled(!store.isWorking)
            }
        }

        Settings {
            SettingsView()
        }
    }
}

import SwiftUI

@main
struct YouTubeDlpDownloaderApp: App {
    @State private var store = DownloadStore()

    var body: some Scene {
        WindowGroup("视频下载", id: "main") {
            ContentView(store: store)
                .frame(minWidth: 860, minHeight: 680)
        }
        .defaultSize(width: 980, height: 820)
        .commands {
            CommandGroup(after: .newItem) {
                Button("解析链接") { store.queryFormats() }
                    .keyboardShortcut(.return, modifiers: [.command])
                    .disabled(!store.canQuery)
                Button("取消当前操作") { store.cancel() }
                    .keyboardShortcut(.escape, modifiers: [])
                    .disabled(!store.isWorking)
                Button("开始下载") { store.download() }
                    .keyboardShortcut("d", modifiers: [.command])
                    .disabled(!store.canDownload)
                Button("在 Finder 中显示") { store.revealCompletedFile() }
                    .keyboardShortcut("r", modifiers: [.command, .shift])
                    .disabled(store.completedFile == nil)
            }
        }

        Settings {
            SettingsView()
                .navigationTitle("设置")
        }
    }
}

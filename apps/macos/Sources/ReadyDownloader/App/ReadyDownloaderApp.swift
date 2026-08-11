import SwiftUI

@main
struct ReadyDownloaderApp: App {
    @StateObject private var store = DownloadStore()
    @AppStorage(AppLanguage.storageKey) private var languageRawValue = AppLanguage.simplifiedChinese.rawValue

    private var language: AppLanguage {
        AppLanguage(rawValue: languageRawValue) ?? .simplifiedChinese
    }

    var body: some Scene {
        WindowGroup("ReadyDownloader", id: "main") {
            ContentView(store: store)
                .frame(minWidth: 860, minHeight: 680)
        }
        .defaultSize(width: 980, height: 820)
        .commands {
            CommandGroup(after: .newItem) {
                Button(language.text("解析链接", "Query URL")) { store.queryFormats() }
                    .keyboardShortcut(.return, modifiers: [.command])
                    .disabled(!store.canQuery)
                Button(language.text("取消当前操作", "Cancel Current Operation")) { store.cancel() }
                    .keyboardShortcut(.escape, modifiers: [])
                    .disabled(!store.isWorking)
                Button(language.text("开始下载", "Start Download")) { store.download() }
                    .keyboardShortcut("d", modifiers: [.command])
                    .disabled(!store.canDownload)
                Button(language.text("在 Finder 中显示", "Show in Finder")) { store.revealCompletedFile() }
                    .keyboardShortcut("r", modifiers: [.command, .shift])
                    .disabled(store.completedFile == nil)
            }
        }

        Settings {
            SettingsView()
                .navigationTitle(language.text("设置", "Settings"))
        }
    }
}

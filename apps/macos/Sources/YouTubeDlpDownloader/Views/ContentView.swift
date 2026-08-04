import AppKit
import SwiftUI

struct ContentView: View {
    @Bindable var store: DownloadStore
    @AppStorage(AppLanguage.storageKey) private var languageRawValue = AppLanguage.simplifiedChinese.rawValue

    private var language: AppLanguage {
        AppLanguage(rawValue: languageRawValue) ?? .simplifiedChinese
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                linkPanel
                DownloadControlsView(store: store)
                formatPanel
                statusPanel
            }
            .padding(26)
        }
        .background(DownloaderTheme.canvas)
        .tint(DownloaderTheme.accent)
        .navigationTitle(language.text("视频下载", "Video Downloader"))
        .onAppear { store.language = language }
        .onChange(of: languageRawValue) { _, _ in store.language = language }
        .onChange(of: store.urlText) { _, _ in
            store.urlDidChange()
        }
        .toolbar {
            ToolbarItemGroup {
                if store.isWorking {
                    Button { store.cancel() } label: {
                        Label(language.text("取消当前操作", "Cancel Current Operation"), systemImage: "xmark.circle")
                    }
                }
                Button { store.revealCompletedFile() } label: {
                    Label(language.text("在 Finder 中显示", "Show in Finder"), systemImage: "folder")
                }
                .disabled(store.completedFile == nil)
                SettingsLink { Label(language.text("设置", "Settings"), systemImage: "gearshape") }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 14) {
            DownloaderMark()
            VStack(alignment: .leading, spacing: 4) {
                Text(language.text("视频下载", "Video Downloader"))
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(DownloaderTheme.ink)
                Text(language.text(
                    "粘贴视频链接，选择画质并保存到你的 Mac。",
                    "Paste a video URL, choose a quality, and save it to your Mac."
                ))
                    .font(.callout)
                    .foregroundStyle(DownloaderTheme.muted)
            }
            Spacer()
        }
    }

    private var linkPanel: some View {
        DownloaderPanel(
            language.text("视频链接", "Video URL"),
            subtitle: language.text(
                "支持 yt-dlp 可解析的视频页面；登录或私密内容可能需要 Cookie。",
                "Supports video pages handled by yt-dlp. Login or private content may require cookies."
            )
        ) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "link")
                            .foregroundStyle(DownloaderTheme.muted)
                        TextField(language.text("粘贴视频页面链接", "Paste a video page URL"), text: $store.urlText)
                            .textFieldStyle(.plain)
                            .onSubmit(store.queryFormats)
                            .disabled(store.isWorking)
                        if !store.urlText.isEmpty && !store.isWorking {
                            Button {
                                store.urlText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(DownloaderTheme.muted)
                            }
                            .buttonStyle(.plain)
                            .help(language.text("清空链接", "Clear URL"))
                        }
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 38)
                    .background(DownloaderTheme.field, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(DownloaderTheme.stroke, lineWidth: 1)
                    }

                    Button(language.text("粘贴", "Paste")) { pasteURL() }
                        .disabled(store.isWorking)

                    Button {
                        store.queryFormats()
                    } label: {
                        Label(language.text("解析链接", "Query URL"), systemImage: "sparkle.magnifyingglass")
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
                    .keyboardShortcut(.return, modifiers: [.command])
                    .disabled(!store.canQuery)
                    .opacity(store.canQuery ? 1 : 0.55)
                }

                Text(language.text(
                    "提示：复制链接后可按 ⌘V 粘贴，按 ⌘↩ 解析。",
                    "Tip: press ⌘V to paste and ⌘↩ to query."
                ))
                    .font(.footnote)
                    .foregroundStyle(DownloaderTheme.muted)
            }
        }
    }

    private var formatPanel: some View {
        DownloaderPanel(
            language.text("可用画质", "Available Formats"),
            subtitle: store.formats.isEmpty
                ? language.text("解析链接后可在这里查看视频格式。", "Query the URL to inspect available video formats.")
                : language.text(
                    "共 \(store.formats.count) 个视频格式；仅在“指定格式”模式下需要手动选择。",
                    "\(store.formats.count) video format(s). Manual selection is only required in Selected Format mode."
                )
        ) {
            FormatTable(
                formats: store.formats,
                selection: $store.selectedFormatID,
                isQuerying: store.isWorking && store.formats.isEmpty,
                hasURL: !store.normalizedURL.isEmpty
            )
            .frame(minHeight: 220, idealHeight: 270, maxHeight: 320)
        }
    }

    private var statusPanel: some View {
        DownloaderPanel(language.text("当前状态", "Current Status")) {
            VStack(alignment: .leading, spacing: 10) {
                DownloaderStatusView(
                    kind: store.statusKind,
                    title: store.status,
                    detail: store.statusDetail,
                    isWorking: store.isWorking
                )

                if let progress = store.progress, let fraction = progress.fractionCompleted {
                    ProgressView(value: fraction)
                        .tint(DownloaderTheme.accent)
                }

                if store.isWorking {
                    Button(language.text("取消当前操作", "Cancel Current Operation")) { store.cancel() }
                        .keyboardShortcut(.escape, modifiers: [])
                }

                if !store.detailedLog.isEmpty {
                    DisclosureGroup(language.text("详细日志", "Detailed Logs")) {
                        ScrollView {
                            Text(store.detailedLog)
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 6)
                        }
                        .frame(maxHeight: 120)
                    }
                    .font(.footnote)
                }
            }
        }
    }

    private func pasteURL() {
        guard let value = NSPasteboard.general.string(forType: .string), !value.isEmpty else { return }
        store.urlText = value
    }
}

import AppKit
import SwiftUI

struct ContentView: View {
    @Bindable var store: DownloadStore

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
        .onChange(of: store.urlText) { _, _ in
            store.urlDidChange()
        }
        .toolbar {
            ToolbarItemGroup {
                if store.isWorking {
                    Button { store.cancel() } label: {
                        Label("取消当前操作", systemImage: "xmark.circle")
                    }
                }
                Button { store.revealCompletedFile() } label: {
                    Label("在 Finder 中显示", systemImage: "folder")
                }
                .disabled(store.completedFile == nil)
                SettingsLink { Label("设置", systemImage: "gearshape") }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 14) {
            DownloaderMark()
            VStack(alignment: .leading, spacing: 4) {
                Text("视频下载")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(DownloaderTheme.ink)
                Text("粘贴视频链接，选择画质并保存到你的 Mac。")
                    .font(.callout)
                    .foregroundStyle(DownloaderTheme.muted)
            }
            Spacer()
        }
    }

    private var linkPanel: some View {
        DownloaderPanel("视频链接", subtitle: "支持 yt-dlp 可解析的视频页面；登录或私密内容可能需要 Cookie。") {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "link")
                            .foregroundStyle(DownloaderTheme.muted)
                        TextField("粘贴视频页面链接", text: $store.urlText)
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
                            .help("清空链接")
                        }
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 38)
                    .background(DownloaderTheme.field, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(DownloaderTheme.stroke, lineWidth: 1)
                    }

                    Button("粘贴") { pasteURL() }
                        .disabled(store.isWorking)

                    Button {
                        store.queryFormats()
                    } label: {
                        Label("解析链接", systemImage: "sparkle.magnifyingglass")
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
                    .keyboardShortcut(.return, modifiers: [.command])
                    .disabled(!store.canQuery)
                    .opacity(store.canQuery ? 1 : 0.55)
                }

                Text("提示：复制链接后可按 ⌘V 粘贴，按 ⌘↩ 解析。")
                    .font(.footnote)
                    .foregroundStyle(DownloaderTheme.muted)
            }
        }
    }

    private var formatPanel: some View {
        DownloaderPanel(
            "可用画质",
            subtitle: store.formats.isEmpty ? "解析链接后可在这里查看视频格式。" : "共 \(store.formats.count) 个视频格式；仅在“指定格式”模式下需要手动选择。"
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
        DownloaderPanel("当前状态") {
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
                    Button("取消当前操作") { store.cancel() }
                        .keyboardShortcut(.escape, modifiers: [])
                }

                if !store.detailedLog.isEmpty {
                    DisclosureGroup("详细日志") {
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

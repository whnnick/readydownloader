import SwiftUI

struct DownloadControlsView: View {
    @Bindable var store: DownloadStore

    var body: some View {
        DownloaderPanel("下载设置", subtitle: "选择画质策略和保存位置。") {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("下载方式")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DownloaderTheme.muted)
                    Picker("下载方式", selection: $store.downloadMode) {
                        ForEach(DownloadMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    Text(store.downloadMode.description)
                        .font(.footnote)
                        .foregroundStyle(DownloaderTheme.muted)
                }

                Divider()

                VStack(alignment: .leading, spacing: 7) {
                    Text("保存位置")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DownloaderTheme.muted)
                    HStack(spacing: 10) {
                        Image(systemName: "folder")
                            .foregroundStyle(DownloaderTheme.muted)
                        Text(store.downloadDirectory.path)
                            .font(.callout)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .help(store.downloadDirectory.path)
                        Spacer()
                        Button("更改…") { store.chooseDownloadDirectory() }
                            .disabled(store.isWorking)
                    }
                    .padding(11)
                    .background(DownloaderTheme.field, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(DownloaderTheme.stroke, lineWidth: 1)
                    }
                }

                if store.downloadMode == .selectedFormat && store.selectedFormat == nil {
                    Label("请先在“可用画质”中选择一个格式。", systemImage: "info.circle")
                        .font(.footnote)
                        .foregroundStyle(DownloaderTheme.muted)
                }

                HStack {
                    Spacer()
                    Button { store.download() } label: {
                        Label(downloadButtonTitle, systemImage: "arrow.down.circle.fill")
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
                    .keyboardShortcut("d", modifiers: [.command])
                    .disabled(!store.canDownload)
                    .opacity(store.canDownload ? 1 : 0.55)
                }
            }
        }
    }

    private var downloadButtonTitle: String {
        switch store.downloadMode {
        case .bestQuality: "下载最高画质"
        case .compatibleMP4: "下载兼容 MP4"
        case .selectedFormat: "下载所选格式"
        }
    }
}

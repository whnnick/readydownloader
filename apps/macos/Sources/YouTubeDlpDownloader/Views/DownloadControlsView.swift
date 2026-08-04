import SwiftUI

struct DownloadControlsView: View {
    @Bindable var store: DownloadStore
    @AppStorage(AppLanguage.storageKey) private var languageRawValue = AppLanguage.simplifiedChinese.rawValue

    private var language: AppLanguage {
        AppLanguage(rawValue: languageRawValue) ?? .simplifiedChinese
    }

    var body: some View {
        DownloaderPanel(
            language.text("下载设置", "Download Settings"),
            subtitle: language.text("选择画质策略和保存位置。", "Choose a quality strategy and save location.")
        ) {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 7) {
                    Text(language.text("下载方式", "Download Mode"))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DownloaderTheme.muted)
                    Picker(language.text("下载方式", "Download Mode"), selection: $store.downloadMode) {
                        ForEach(DownloadMode.allCases) { mode in
                            Text(mode.title(language: language)).tag(mode)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    Text(store.downloadMode.description(language: language))
                        .font(.footnote)
                        .foregroundStyle(DownloaderTheme.muted)
                }

                Divider()

                VStack(alignment: .leading, spacing: 7) {
                    Text(language.text("保存位置", "Save Location"))
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
                        Button(language.text("更改…", "Change…")) { store.chooseDownloadDirectory() }
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
                    Label(
                        language.text(
                            "请先在“可用画质”中选择一个格式。",
                            "Select a format from Available Formats first."
                        ),
                        systemImage: "info.circle"
                    )
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
        case .bestQuality: language.text("下载最高画质", "Download Best Quality")
        case .compatibleMP4: language.text("下载兼容 MP4", "Download Compatible MP4")
        case .selectedFormat: language.text("下载所选格式", "Download Selected Format")
        }
    }
}

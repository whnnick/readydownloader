import SwiftUI

struct SettingsView: View {
    @AppStorage(AppLanguage.storageKey) private var languageRawValue = AppLanguage.simplifiedChinese.rawValue
    @AppStorage("networkMode") private var networkMode = NetworkMode.system.rawValue
    @AppStorage("proxyURL") private var proxyURL = ""
    @AppStorage("cookiePath") private var cookiePath = ""
    @AppStorage("detailedLogsEnabled") private var detailedLogsEnabled = false

    private var language: AppLanguage {
        AppLanguage(rawValue: languageRawValue) ?? .simplifiedChinese
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(language.text("设置", "Settings"))
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(DownloaderTheme.ink)
                    Text(language.text(
                        "配置语言、网络访问、登录信息和诊断选项。",
                        "Configure language, network access, login information, and diagnostics."
                    ))
                        .foregroundStyle(DownloaderTheme.muted)
                }

                DownloaderPanel("语言 / Language", subtitle: language.text("选择应用界面语言，修改后立即生效。", "Choose the interface language. Changes apply immediately.")) {
                    Picker("语言 / Language", selection: $languageRawValue) {
                        ForEach(AppLanguage.allCases) { option in
                            Text(option.displayName).tag(option.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                DownloaderPanel(
                    language.text("网络", "Network"),
                    subtitle: language.text(
                        "默认跟随 macOS 系统代理；只有在需要时才填写自定义代理。",
                        "Uses the macOS system proxy by default. Enter a custom proxy only when needed."
                    )
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        Picker(language.text("连接方式", "Connection"), selection: $networkMode) {
                            ForEach(NetworkMode.allCases) { mode in
                                Text(mode.title(language: language)).tag(mode.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)

                        TextField(
                            language.text(
                                "代理地址，例如 http://127.0.0.1:7890",
                                "Proxy URL, for example http://127.0.0.1:7890"
                            ),
                            text: $proxyURL
                        )
                            .disabled(networkMode != NetworkMode.custom.rawValue)
                            .textFieldStyle(.roundedBorder)
                    }
                }

                DownloaderPanel(
                    language.text("登录与隐私", "Login & Privacy"),
                    subtitle: language.text(
                        "公开内容通常无需 Cookie；登录、年龄限制或私密内容可能需要。",
                        "Public content usually needs no cookies. Login, age-restricted, or private content may require them."
                    )
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        TextField(language.text("Cookie 文件路径（可选）", "Cookie file path (optional)"), text: $cookiePath)
                            .textFieldStyle(.roundedBorder)
                        Label(
                            language.text(
                                "Cookie 包含私人登录信息。应用只在本机读取，不会把内容写入日志。",
                                "Cookies contain private login data. The app reads them locally and never writes their contents to logs."
                            ),
                            systemImage: "lock.shield"
                        )
                            .font(.footnote)
                            .foregroundStyle(DownloaderTheme.muted)
                    }
                }

                DownloaderPanel(
                    language.text("诊断", "Diagnostics"),
                    subtitle: language.text(
                        "遇到解析或下载问题时，可临时开启详细日志。",
                        "Temporarily enable detailed logs when troubleshooting a query or download."
                    )
                ) {
                    Toggle(language.text("显示详细 yt-dlp 日志", "Show detailed yt-dlp logs"), isOn: $detailedLogsEnabled)
                    Text(language.text(
                        "日志可能包含链接或平台返回信息，提交问题前请先检查并脱敏。",
                        "Logs may contain URLs or service responses. Review and redact them before reporting an issue."
                    ))
                        .font(.footnote)
                        .foregroundStyle(DownloaderTheme.muted)
                }
            }
            .padding(26)
        }
        .background(DownloaderTheme.canvas)
        .tint(DownloaderTheme.accent)
        .frame(width: 600, height: 560)
    }
}

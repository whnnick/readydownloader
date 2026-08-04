import SwiftUI

struct SettingsView: View {
    @AppStorage("networkMode") private var networkMode = NetworkMode.system.rawValue
    @AppStorage("proxyURL") private var proxyURL = ""
    @AppStorage("cookiePath") private var cookiePath = ""
    @AppStorage("detailedLogsEnabled") private var detailedLogsEnabled = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("设置")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(DownloaderTheme.ink)
                    Text("配置网络访问、登录信息和诊断选项。")
                        .foregroundStyle(DownloaderTheme.muted)
                }

                DownloaderPanel("网络", subtitle: "默认跟随 macOS 系统代理；只有在需要时才填写自定义代理。") {
                    VStack(alignment: .leading, spacing: 12) {
                        Picker("连接方式", selection: $networkMode) {
                            ForEach(NetworkMode.allCases) { mode in
                                Text(mode.title).tag(mode.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)

                        TextField("代理地址，例如 http://127.0.0.1:7890", text: $proxyURL)
                            .disabled(networkMode != NetworkMode.custom.rawValue)
                            .textFieldStyle(.roundedBorder)
                    }
                }

                DownloaderPanel("登录与隐私", subtitle: "公开内容通常无需 Cookie；登录、年龄限制或私密内容可能需要。") {
                    VStack(alignment: .leading, spacing: 10) {
                        TextField("Cookie 文件路径（可选）", text: $cookiePath)
                            .textFieldStyle(.roundedBorder)
                        Label("Cookie 包含私人登录信息。应用只在本机读取，不会把内容写入日志。", systemImage: "lock.shield")
                            .font(.footnote)
                            .foregroundStyle(DownloaderTheme.muted)
                    }
                }

                DownloaderPanel("诊断", subtitle: "遇到解析或下载问题时，可临时开启详细日志。") {
                    Toggle("显示详细 yt-dlp 日志", isOn: $detailedLogsEnabled)
                    Text("日志可能包含链接或平台返回信息，提交问题前请先检查并脱敏。")
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

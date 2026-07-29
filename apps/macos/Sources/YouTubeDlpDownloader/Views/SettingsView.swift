import SwiftUI

struct SettingsView: View {
    @AppStorage("networkMode") private var networkMode = NetworkMode.system.rawValue
    @AppStorage("proxyURL") private var proxyURL = ""
    @AppStorage("cookiePath") private var cookiePath = ""
    @AppStorage("detailedLogsEnabled") private var detailedLogsEnabled = false

    var body: some View {
        Form {
            Picker("Network mode", selection: $networkMode) {
                ForEach(NetworkMode.allCases) { mode in
                    Text(mode.title).tag(mode.rawValue)
                }
            }
            TextField("Custom proxy URL", text: $proxyURL)
                .disabled(networkMode != NetworkMode.custom.rawValue)
            TextField("Optional cookie file", text: $cookiePath)
            Text("Cookie files contain private login data. They stay outside the app and must never be committed or attached to an issue.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Toggle("Show detailed yt-dlp logs", isOn: $detailedLogsEnabled)
        }
        .formStyle(.grouped)
        .frame(width: 520, height: 290)
        .scenePadding()
    }
}

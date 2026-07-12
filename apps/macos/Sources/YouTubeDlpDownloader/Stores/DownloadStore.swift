import Foundation
import Observation

@MainActor
@Observable
final class DownloadStore {
    var urlText = ""
    var formats: [YtDlpFormat] = []
    var selectedFormatID: YtDlpFormat.ID?
    var status = "Enter a media URL, then query available formats."
    var detailedLog = ""
    var isWorking = false

    private let client = YtDlpClient()
    private let resolver = ToolchainResolver()
    private var operation: Task<Void, Never>?

    func queryFormats() {
        let trimmedURL = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedURL.isEmpty else {
            status = "Enter a URL before querying formats."
            return
        }

        operation?.cancel()
        isWorking = true
        formats = []
        selectedFormatID = nil
        status = "Checking the local toolchain…"

        let toolchain = resolver.resolve()
        let missing = resolver.missingQueryTools(in: toolchain)
        guard missing.isEmpty else {
            status = "Missing required tools: \(missing.map(\.lastPathComponent).joined(separator: ", "))."
            detailedLog = missing.map(\.path).joined(separator: "\n")
            isWorking = false
            return
        }

        let settings = QuerySettings.current
        status = "Querying formats…"
        operation = Task { [weak self] in
            guard let self else { return }
            do {
                let parsed = try await client.queryFormats(
                    url: trimmedURL,
                    toolchain: toolchain,
                    networkMode: settings.networkMode,
                    proxyURL: settings.proxyURL,
                    cookiePath: settings.cookiePath
                )
                guard !Task.isCancelled else { return }
                formats = parsed
                selectedFormatID = parsed.first?.id
                status = parsed.isEmpty ? "No downloadable video formats were found." : "Found \(parsed.count) video formats."
                detailedLog = ""
            } catch is CancellationError {
                status = "Operation cancelled."
            } catch {
                status = "Could not query formats."
                detailedLog = error.localizedDescription
            }
            isWorking = false
        }
    }

    func cancel() {
        operation?.cancel()
        operation = nil
        Task { await client.cancel() }
        isWorking = false
        status = "Operation cancelled."
    }
}

private struct QuerySettings: Sendable {
    let networkMode: NetworkMode
    let proxyURL: String
    let cookiePath: String

    static var current: QuerySettings {
        let defaults = UserDefaults.standard
        let rawMode = defaults.string(forKey: "networkMode") ?? NetworkMode.system.rawValue
        return QuerySettings(
            networkMode: NetworkMode(rawValue: rawMode) ?? .system,
            proxyURL: defaults.string(forKey: "proxyURL") ?? "",
            cookiePath: defaults.string(forKey: "cookiePath") ?? ""
        )
    }
}

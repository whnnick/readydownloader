import Foundation
import Observation

@MainActor
@Observable
final class DownloadStore {
    var urlText = ""
    var formats: [YtDlpFormat] = []
    var selectedFormatID: YtDlpFormat.ID?
    var downloadMode = DownloadMode.bestQuality
    var downloadDirectory: URL
    var progress: DownloadProgress?
    var completedFile: URL?
    var status = "Enter a media URL, then query available formats."
    var detailedLog = ""
    var isWorking = false

    private let client = YtDlpClient()
    private let resolver = ToolchainResolver()
    private let directoryStore = DownloadDirectoryStore()
    private var operation: Task<Void, Never>?

    init() {
        downloadDirectory = directoryStore.currentDirectory()
    }

    var selectedFormat: YtDlpFormat? {
        formats.first { $0.id == selectedFormatID }
    }

    var canDownload: Bool {
        guard !isWorking, !urlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }
        return downloadMode != .selectedFormat || selectedFormat != nil
    }

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
        progress = nil
        completedFile = nil
        status = "Checking the local toolchain…"

        let settings = QuerySettings.current
        let toolchain = resolver.resolve()
        let missing = resolver.missingQueryTools(in: toolchain)
        guard missing.isEmpty else {
            status = "Missing required tools: \(missing.map(\.lastPathComponent).joined(separator: ", "))."
            detailedLog = settings.detailedLogsEnabled
                ? missing.map(\.path).joined(separator: "\n")
                : ""
            isWorking = false
            return
        }

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
                handleOperationFailure(
                    status: "Could not query formats.",
                    errorDescription: error.localizedDescription,
                    includeDetailedLogs: settings.detailedLogsEnabled
                )
            }
            isWorking = false
        }
    }

    func download() {
        let trimmedURL = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedURL.isEmpty else {
            status = "Enter a URL before downloading."
            return
        }
        if downloadMode == .selectedFormat, selectedFormat == nil {
            status = "Select a format before using Selected Format mode."
            return
        }

        let settings = QuerySettings.current
        let toolchain = resolver.resolve()
        let missing = resolver.missingDownloadTools(in: toolchain)
        guard missing.isEmpty else {
            status = "Missing required tools: \(missing.map(\.lastPathComponent).joined(separator: ", "))."
            detailedLog = settings.detailedLogsEnabled
                ? missing.map(\.path).joined(separator: "\n")
                : ""
            return
        }

        operation?.cancel()
        isWorking = true
        progress = nil
        completedFile = nil
        detailedLog = ""
        status = "Starting download…"

        let mode = downloadMode
        let format = selectedFormat
        let destination = downloadDirectory
        let accessedSecurityScope = destination.startAccessingSecurityScopedResource()

        operation = Task { [weak self] in
            guard let self else { return }
            defer {
                if accessedSecurityScope { destination.stopAccessingSecurityScopedResource() }
            }
            do {
                let file = try await client.download(
                    url: trimmedURL,
                    mode: mode,
                    selectedFormat: format,
                    destination: destination,
                    toolchain: toolchain,
                    networkMode: settings.networkMode,
                    proxyURL: settings.proxyURL,
                    cookiePath: settings.cookiePath,
                    onOutput: { [weak self] line in
                        Task { @MainActor in
                            self?.handleDownloadOutput(
                                line,
                                includeDetailedLogs: settings.detailedLogsEnabled
                            )
                        }
                    }
                )
                guard !Task.isCancelled else { return }
                completedFile = file
                progress = DownloadProgress(
                    fractionCompleted: 1,
                    percentText: "100%",
                    speed: "—",
                    eta: "00:00"
                )
                status = file.map { "Download complete: \($0.lastPathComponent)" }
                    ?? "Download complete in \(destination.path)."
            } catch is CancellationError {
                status = "Download cancelled."
            } catch {
                handleOperationFailure(
                    status: "Download failed.",
                    errorDescription: error.localizedDescription,
                    includeDetailedLogs: settings.detailedLogsEnabled
                )
            }
            isWorking = false
        }
    }

    func chooseDownloadDirectory() {
        guard !isWorking, let selected = directoryStore.chooseDirectory() else { return }
        downloadDirectory = selected
    }

    func revealCompletedFile() {
        guard let completedFile else { return }
        directoryStore.reveal(completedFile)
    }

    func cancel() {
        operation?.cancel()
        operation = nil
        Task { await client.cancel() }
        isWorking = false
        status = "Operation cancelled."
    }

    func handleDownloadOutput(_ line: String, includeDetailedLogs: Bool) {
        if let parsedProgress = DownloadProgress.parse(line: line) {
            progress = parsedProgress
            status = "Downloading \(parsedProgress.percentText) · \(parsedProgress.speed) · ETA \(parsedProgress.eta)"
        } else if includeDetailedLogs {
            appendDetailedLog(line)
        }
    }

    func handleOperationFailure(
        status: String,
        errorDescription: String,
        includeDetailedLogs: Bool
    ) {
        self.status = status
        detailedLog = includeDetailedLogs ? errorDescription : ""
    }

    private func appendDetailedLog(_ line: String) {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        detailedLog += detailedLog.isEmpty ? trimmed : "\n\(trimmed)"
        if detailedLog.count > 50_000 {
            detailedLog = String(detailedLog.suffix(50_000))
        }
    }
}

private struct QuerySettings: Sendable {
    let networkMode: NetworkMode
    let proxyURL: String
    let cookiePath: String
    let detailedLogsEnabled: Bool

    static var current: QuerySettings {
        let defaults = UserDefaults.standard
        let rawMode = defaults.string(forKey: "networkMode") ?? NetworkMode.system.rawValue
        return QuerySettings(
            networkMode: NetworkMode(rawValue: rawMode) ?? .system,
            proxyURL: defaults.string(forKey: "proxyURL") ?? "",
            cookiePath: defaults.string(forKey: "cookiePath") ?? "",
            detailedLogsEnabled: defaults.bool(forKey: "detailedLogsEnabled")
        )
    }
}

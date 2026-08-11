import Combine
import Foundation

@MainActor
final class DownloadStore: ObservableObject {
    @Published var urlText = ""
    @Published var formats: [YtDlpFormat] = []
    @Published var selectedFormatID: YtDlpFormat.ID?
    @Published var downloadMode = DownloadMode.bestQuality
    @Published var downloadDirectory: URL
    @Published var progress: DownloadProgress?
    @Published var completedFile: URL?
    @Published var language = AppLanguage.current
    @Published var statusState = DownloadStatusState.ready
    @Published var detailedLog = ""
    @Published var isWorking = false
    @Published private(set) var analyzedURL: String?

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

    var status: String { statusState.title(language: language) }
    var statusDetail: String { statusState.detail(language: language) }
    var statusKind: DownloadStatusKind { statusState.kind }

    var canDownload: Bool {
        guard !isWorking, analyzedURL == normalizedURL, !formats.isEmpty else {
            return false
        }
        return downloadMode != .selectedFormat || selectedFormat != nil
    }

    var canQuery: Bool {
        !isWorking && Self.isValidMediaURL(normalizedURL)
    }

    var normalizedURL: String {
        urlText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func urlDidChange() {
        guard normalizedURL != analyzedURL else { return }
        formats = []
        selectedFormatID = nil
        progress = nil
        completedFile = nil
        statusState = .waitingForQuery(hasURL: !normalizedURL.isEmpty)
    }

    func queryFormats() {
        let trimmedURL = normalizedURL
        guard Self.isValidMediaURL(trimmedURL) else {
            statusState = .invalidURL
            return
        }

        operation?.cancel()
        isWorking = true
        formats = []
        selectedFormatID = nil
        progress = nil
        completedFile = nil
        analyzedURL = nil
        statusState = .checkingTools

        let settings = QuerySettings.current
        let toolchain = resolver.resolve()
        let missing = resolver.missingQueryTools(in: toolchain)
        guard missing.isEmpty else {
            statusState = .missingTools(missing.map(\.lastPathComponent))
            detailedLog = settings.detailedLogsEnabled
                ? missing.map(\.path).joined(separator: "\n")
                : ""
            isWorking = false
            return
        }

        statusState = .querying
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
                analyzedURL = trimmedURL
                statusState = parsed.isEmpty ? .noFormats : .queryComplete(parsed.count)
                detailedLog = ""
            } catch is CancellationError {
                statusState = .queryCancelled
            } catch {
                handleOperationFailure(
                    operation: .query,
                    errorDescription: error.localizedDescription,
                    includeDetailedLogs: settings.detailedLogsEnabled
                )
            }
            isWorking = false
        }
    }

    func download() {
        let trimmedURL = normalizedURL
        guard analyzedURL == trimmedURL, !formats.isEmpty else {
            statusState = .queryRequired
            return
        }
        if downloadMode == .selectedFormat, selectedFormat == nil {
            statusState = .formatRequired
            return
        }

        let settings = QuerySettings.current
        let toolchain = resolver.resolve()
        let missing = resolver.missingDownloadTools(in: toolchain)
        guard missing.isEmpty else {
            statusState = .missingTools(missing.map(\.lastPathComponent))
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
        statusState = .preparingDownload(downloadDirectory.lastPathComponent)

        let mode = downloadMode
        let format = selectedFormat
        let destination = downloadDirectory
        let accessedSecurityScope = destination.startAccessingSecurityScopedResource()

        operation = Task { [weak self] in
            guard let self else { return }
            let callbackStore = self
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
                    onOutput: { [callbackStore] line in
                        Task { @MainActor [callbackStore] in
                            callbackStore.handleDownloadOutput(
                                line,
                                includeDetailedLogs: settings.detailedLogsEnabled
                            )
                        }
                    },
                    onStage: { [callbackStore] stage in
                        Task { @MainActor [callbackStore] in
                            switch stage {
                            case .makingIPhoneCompatible:
                                callbackStore.progress = nil
                                callbackStore.statusState = .makingIPhoneCompatible
                            }
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
                statusState = .downloadComplete(
                    fileName: file?.lastPathComponent,
                    directoryPath: destination.path
                )
            } catch is CancellationError {
                statusState = .downloadCancelled
            } catch {
                handleOperationFailure(
                    operation: .download,
                    errorDescription: error.localizedDescription,
                    includeDetailedLogs: settings.detailedLogsEnabled
                )
            }
            isWorking = false
        }
    }

    func chooseDownloadDirectory() {
        guard !isWorking, let selected = directoryStore.chooseDirectory(language: language) else { return }
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
        statusState = .operationCancelled
    }

    func handleDownloadOutput(_ line: String, includeDetailedLogs: Bool) {
        if let parsedProgress = DownloadProgress.parse(line: line) {
            progress = parsedProgress
            statusState = .downloading(parsedProgress)
        } else if includeDetailedLogs {
            appendDetailedLog(line)
        }
    }

    func handleOperationFailure(
        operation: FailedOperation,
        errorDescription: String,
        includeDetailedLogs: Bool
    ) {
        statusState = operation == .query
            ? .queryFailed(errorDescription)
            : .downloadFailed(errorDescription)
        detailedLog = includeDetailedLogs ? errorDescription : ""
    }

    static func isValidMediaURL(_ value: String) -> Bool {
        guard let components = URLComponents(string: value),
              let scheme = components.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              components.host?.isEmpty == false else {
            return false
        }
        return true
    }

    nonisolated static func friendlyErrorMessage(
        for errorDescription: String,
        language: AppLanguage = .current
    ) -> String {
        let message = errorDescription.lowercased()
        if message.contains("login") || message.contains("cookie") || message.contains("authentication") {
            return language.text(
                "该内容可能需要登录。请在设置中选择有效的 Cookie 文件后重试。",
                "This content may require login. Select a valid cookie file in Settings and try again."
            )
        }
        if message.contains("unsupported url") || message.contains("no suitable extractor") {
            return language.text(
                "当前链接暂不受支持，请确认它是具体的视频页面链接。",
                "This URL is not currently supported. Make sure it points to a specific video page."
            )
        }
        if message.contains("timed out") || message.contains("network") || message.contains("connection") {
            return language.text(
                "网络连接超时，请检查网络或代理设置后重试。",
                "The network connection timed out. Check the network or proxy settings and try again."
            )
        }
        if message.contains("not available") || message.contains("unavailable") || message.contains("private") {
            return language.text(
                "该视频当前不可访问，可能已删除、设为私密或受地区限制。",
                "The video is unavailable. It may have been removed, made private, or region restricted."
            )
        }
        return language.text(
            "请检查链接、网络和平台访问权限后重试；详细原因可在设置中开启日志查看。",
            "Check the URL, network, and service access, then try again. Enable detailed logs in Settings for more information."
        )
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

enum FailedOperation: Equatable, Sendable {
    case query
    case download
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

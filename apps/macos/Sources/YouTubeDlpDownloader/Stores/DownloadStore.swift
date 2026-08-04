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
    var status = "准备就绪"
    var statusDetail = "粘贴视频链接，解析后即可选择画质并下载。"
    var statusKind = DownloadStatusKind.neutral
    var detailedLog = ""
    var isWorking = false
    private(set) var analyzedURL: String?

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
        status = "等待解析"
        statusDetail = normalizedURL.isEmpty
            ? "粘贴视频链接，解析后即可选择画质并下载。"
            : "点击“解析链接”读取视频信息和可用画质。"
        statusKind = .neutral
    }

    func queryFormats() {
        let trimmedURL = normalizedURL
        guard Self.isValidMediaURL(trimmedURL) else {
            status = "链接无效"
            statusDetail = "请输入完整的 http 或 https 视频链接。"
            statusKind = .failure
            return
        }

        operation?.cancel()
        isWorking = true
        formats = []
        selectedFormatID = nil
        progress = nil
        completedFile = nil
        analyzedURL = nil
        status = "正在检查运行组件"
        statusDetail = "确认 yt-dlp 和视频处理组件可以正常使用。"
        statusKind = .progress

        let settings = QuerySettings.current
        let toolchain = resolver.resolve()
        let missing = resolver.missingQueryTools(in: toolchain)
        guard missing.isEmpty else {
            status = "缺少运行组件"
            statusDetail = "请重新安装应用，缺少：\(missing.map(\.lastPathComponent).joined(separator: "、"))。"
            statusKind = .failure
            detailedLog = settings.detailedLogsEnabled
                ? missing.map(\.path).joined(separator: "\n")
                : ""
            isWorking = false
            return
        }

        status = "正在解析视频"
        statusDetail = "部分平台需要十几秒，请保持网络连接。"
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
                status = parsed.isEmpty ? "没有找到可下载格式" : "视频解析完成"
                statusDetail = parsed.isEmpty
                    ? "该链接可能需要登录、Cookie，或暂不受支持。"
                    : "已找到 \(parsed.count) 个视频格式，可以选择下载方式。"
                statusKind = parsed.isEmpty ? .failure : .success
                detailedLog = ""
            } catch is CancellationError {
                status = "已取消解析"
                statusDetail = "可以修改链接后重新解析。"
                statusKind = .neutral
            } catch {
                handleOperationFailure(
                    status: "解析失败",
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
            status = "请先解析链接"
            statusDetail = "解析完成后才能开始下载，避免下载错误的内容。"
            statusKind = .failure
            return
        }
        if downloadMode == .selectedFormat, selectedFormat == nil {
            status = "请选择一个格式"
            statusDetail = "使用指定格式时，需要在可用画质列表中选中一项。"
            statusKind = .failure
            return
        }

        let settings = QuerySettings.current
        let toolchain = resolver.resolve()
        let missing = resolver.missingDownloadTools(in: toolchain)
        guard missing.isEmpty else {
            status = "缺少运行组件"
            statusDetail = "请重新安装应用，缺少：\(missing.map(\.lastPathComponent).joined(separator: "、"))。"
            statusKind = .failure
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
        status = "正在准备下载"
        statusDetail = "即将保存到 \(downloadDirectory.lastPathComponent)。"
        statusKind = .progress

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
                status = "下载完成"
                statusDetail = file.map { "已保存：\($0.lastPathComponent)" }
                    ?? "文件已保存到 \(destination.path)。"
                statusKind = .success
            } catch is CancellationError {
                status = "下载已取消"
                statusDetail = "未完成的临时文件会由下载工具处理。"
                statusKind = .neutral
            } catch {
                handleOperationFailure(
                    status: "下载失败",
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
        status = "操作已取消"
        statusDetail = "可以修改设置后重新开始。"
        statusKind = .neutral
    }

    func handleDownloadOutput(_ line: String, includeDetailedLogs: Bool) {
        if let parsedProgress = DownloadProgress.parse(line: line) {
            progress = parsedProgress
            status = "正在下载 \(parsedProgress.percentText)"
            statusDetail = "速度 \(parsedProgress.speed) · 预计剩余 \(parsedProgress.eta)"
            statusKind = .progress
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
        statusDetail = Self.friendlyErrorMessage(for: errorDescription)
        statusKind = .failure
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

    static func friendlyErrorMessage(for errorDescription: String) -> String {
        let message = errorDescription.lowercased()
        if message.contains("login") || message.contains("cookie") || message.contains("authentication") {
            return "该内容可能需要登录。请在设置中选择有效的 Cookie 文件后重试。"
        }
        if message.contains("unsupported url") || message.contains("no suitable extractor") {
            return "当前链接暂不受支持，请确认它是具体的视频页面链接。"
        }
        if message.contains("timed out") || message.contains("network") || message.contains("connection") {
            return "网络连接超时，请检查网络或代理设置后重试。"
        }
        if message.contains("not available") || message.contains("unavailable") || message.contains("private") {
            return "该视频当前不可访问，可能已删除、设为私密或受地区限制。"
        }
        return "请检查链接、网络和平台访问权限后重试；详细原因可在设置中开启日志查看。"
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

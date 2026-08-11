import Foundation

struct ToolProcessResult: Sendable {
    let exitCode: Int32
    let stdout: Data
    let stderr: Data
}

enum YtDlpClientError: LocalizedError {
    case couldNotLaunch(String, String)
    case failed(Int32, String)
    case missingDownloadedFile
    case compatibilityConversionFailed(Int32, String)

    var errorDescription: String? {
        switch self {
        case .couldNotLaunch(let tool, let message):
            AppLanguage.current.text("无法启动 \(tool)：\(message)", "Could not launch \(tool): \(message)")
        case .failed(let code, let message):
            message.isEmpty
                ? AppLanguage.current.text("yt-dlp 已退出，错误代码：\(code)。", "yt-dlp exited with code \(code).")
                : message
        case .missingDownloadedFile:
            AppLanguage.current.text(
                "下载完成，但没有找到输出文件路径。",
                "The download finished, but the output file path was not found."
            )
        case .compatibilityConversionFailed(let code, let message):
            message.isEmpty
                ? AppLanguage.current.text(
                    "兼容性转换失败，错误代码：\(code)。",
                    "Compatibility conversion failed with code \(code)."
                )
                : message
        }
    }
}

enum DownloadStage: Sendable {
    case makingIPhoneCompatible
}

actor YtDlpClient {
    private var currentProcess: Process?

    func queryFormats(
        url: String,
        toolchain: Toolchain,
        networkMode: NetworkMode,
        proxyURL: String,
        cookiePath: String
    ) async throws -> [YtDlpFormat] {
        var arguments = commonArguments(
            toolchain: toolchain,
            networkMode: networkMode,
            proxyURL: proxyURL,
            cookiePath: cookiePath
        )
        arguments.append(contentsOf: ["--no-playlist", "-J", url])
        let result = try await run(toolName: "yt-dlp", executable: toolchain.ytDlp, arguments: arguments)
        guard result.exitCode == 0 else {
            throw YtDlpClientError.failed(
                result.exitCode,
                String(decoding: result.stderr, as: UTF8.self)
            )
        }
        return try FormatParser.parse(result.stdout)
    }

    func download(
        url: String,
        mode: DownloadMode,
        selectedFormat: YtDlpFormat?,
        destination: URL,
        toolchain: Toolchain,
        networkMode: NetworkMode,
        proxyURL: String,
        cookiePath: String,
        onOutput: @escaping @Sendable (String) -> Void,
        onStage: @escaping @Sendable (DownloadStage) -> Void
    ) async throws -> URL? {
        var arguments = commonArguments(
            toolchain: toolchain,
            networkMode: networkMode,
            proxyURL: proxyURL,
            cookiePath: cookiePath
        )
        arguments.append(contentsOf: [
            "--no-playlist",
            "--progress",
            "--newline",
            "--progress-template", DownloadProgress.ytDlpTemplate,
            "--print", "after_move:filepath",
            "-f", try mode.formatSelector(selectedFormat: selectedFormat)
        ])
        if mode == .compatibleMP4 {
            arguments.append(contentsOf: ["--merge-output-format", "mp4"])
        }
        arguments.append(contentsOf: ["-P", destination.path, url])

        let result = try await run(
            toolName: "yt-dlp",
            executable: toolchain.ytDlp,
            arguments: arguments,
            onStandardOutput: onOutput,
            onStandardError: onOutput
        )
        guard result.exitCode == 0 else {
            let stderr = String(decoding: result.stderr, as: UTF8.self)
            let stdout = String(decoding: result.stdout, as: UTF8.self)
            throw YtDlpClientError.failed(result.exitCode, stderr.isEmpty ? stdout : stderr)
        }
        guard let downloadedFile = Self.downloadedFile(from: result.stdout) else {
            throw YtDlpClientError.missingDownloadedFile
        }
        guard mode == .compatibleMP4 else { return downloadedFile }
        return try await makeIPhoneCompatible(
            downloadedFile,
            toolchain: toolchain,
            onOutput: onOutput,
            onStage: onStage
        )
    }

    func cancel() {
        currentProcess?.terminate()
        currentProcess = nil
    }

    private func commonArguments(
        toolchain: Toolchain,
        networkMode: NetworkMode,
        proxyURL: String,
        cookiePath: String
    ) -> [String] {
        var arguments = ["--ignore-config"]
        switch networkMode {
        case .direct:
            arguments.append("--proxy=")
        case .system:
            break
        case .custom:
            if !proxyURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                arguments.append(contentsOf: ["--proxy", proxyURL])
            }
        }
        arguments.append(contentsOf: [
            "--force-ipv4",
            "--js-runtimes", "deno:\(toolchain.deno.path)",
            "--ffmpeg-location", toolchain.ffmpeg.deletingLastPathComponent().path,
            "--socket-timeout", "60"
        ])
        if !cookiePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            arguments.append(contentsOf: ["--cookies", cookiePath])
        }
        return arguments
    }

    private func makeIPhoneCompatible(
        _ file: URL,
        toolchain: Toolchain,
        onOutput: @escaping @Sendable (String) -> Void,
        onStage: @escaping @Sendable (DownloadStage) -> Void
    ) async throws -> URL {
        let probe = try await run(
            toolName: "ffprobe",
            executable: toolchain.ffprobe,
            arguments: CompatibleMedia.probeArguments(file: file)
        )
        guard probe.exitCode == 0 else {
            throw YtDlpClientError.compatibilityConversionFailed(
                probe.exitCode,
                String(decoding: probe.stderr, as: UTF8.self)
            )
        }
        guard try !CompatibleMedia.isIPhoneCompatible(probeData: probe.stdout) else {
            return file
        }

        onStage(.makingIPhoneCompatible)
        let temporary = file.deletingLastPathComponent().appending(
            path: ".\(file.deletingPathExtension().lastPathComponent).iphone-\(UUID().uuidString).mp4"
        )
        defer { try? FileManager.default.removeItem(at: temporary) }

        let conversion = try await run(
            toolName: "ffmpeg",
            executable: toolchain.ffmpeg,
            arguments: CompatibleMedia.transcodeArguments(input: file, output: temporary),
            onStandardOutput: onOutput,
            onStandardError: onOutput
        )
        guard conversion.exitCode == 0 else {
            throw YtDlpClientError.compatibilityConversionFailed(
                conversion.exitCode,
                String(decoding: conversion.stderr, as: UTF8.self)
            )
        }

        try replaceOriginal(file, with: temporary)
        return file
    }

    private func replaceOriginal(_ original: URL, with replacement: URL) throws {
        let fileManager = FileManager.default
        let backup = original.deletingLastPathComponent().appending(
            path: ".\(original.lastPathComponent).backup-\(UUID().uuidString)"
        )
        try fileManager.moveItem(at: original, to: backup)
        do {
            try fileManager.moveItem(at: replacement, to: original)
            try? fileManager.removeItem(at: backup)
        } catch {
            try? fileManager.moveItem(at: backup, to: original)
            throw error
        }
    }

    private func run(
        toolName: String,
        executable: URL,
        arguments: [String],
        onStandardOutput: (@Sendable (String) -> Void)? = nil,
        onStandardError: (@Sendable (String) -> Void)? = nil
    ) async throws -> ToolProcessResult {
        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.executableURL = executable
        process.arguments = arguments
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        currentProcess = process

        do {
            try process.run()
        } catch {
            currentProcess = nil
            throw YtDlpClientError.couldNotLaunch(toolName, error.localizedDescription)
        }

        async let stdout = Self.readLines(outputPipe.fileHandleForReading, onLine: onStandardOutput)
        async let stderr = Self.readLines(errorPipe.fileHandleForReading, onLine: onStandardError)
        await Self.waitForExit(process)
        let result = ToolProcessResult(
            exitCode: process.terminationStatus,
            stdout: try await stdout,
            stderr: try await stderr
        )
        currentProcess = nil
        if Task.isCancelled { throw CancellationError() }
        return result
    }

    private nonisolated static func readLines(
        _ handle: FileHandle,
        onLine: (@Sendable (String) -> Void)?
    ) async throws -> Data {
        var collected = Data()
        for try await line in handle.bytes.lines {
            collected.append(contentsOf: line.utf8)
            collected.append(0x0A)
            onLine?(line)
        }
        return collected
    }

    private nonisolated static func waitForExit(_ process: Process) async {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                process.waitUntilExit()
                continuation.resume()
            }
        }
    }

    private nonisolated static func downloadedFile(from output: Data) -> URL? {
        let lines = String(decoding: output, as: UTF8.self)
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        for line in lines.reversed() where line.hasPrefix("/") {
            return URL(filePath: line)
        }
        return nil
    }
}

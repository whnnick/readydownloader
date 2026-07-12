import Foundation

struct ToolProcessResult: Sendable {
    let exitCode: Int32
    let stdout: Data
    let stderr: Data
}

enum YtDlpClientError: LocalizedError {
    case couldNotLaunch(String)
    case failed(Int32, String)

    var errorDescription: String? {
        switch self {
        case .couldNotLaunch(let message): "Could not launch yt-dlp: \(message)"
        case .failed(let code, let message): message.isEmpty ? "yt-dlp exited with code \(code)." : message
        }
    }
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
        let result = try await run(executable: toolchain.ytDlp, arguments: arguments)
        guard result.exitCode == 0 else {
            throw YtDlpClientError.failed(
                result.exitCode,
                String(decoding: result.stderr, as: UTF8.self)
            )
        }
        return try FormatParser.parse(result.stdout)
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

    private func run(executable: URL, arguments: [String]) async throws -> ToolProcessResult {
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
            throw YtDlpClientError.couldNotLaunch(error.localizedDescription)
        }

        async let stdout = Self.readAll(outputPipe.fileHandleForReading)
        async let stderr = Self.readAll(errorPipe.fileHandleForReading)
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

    private nonisolated static func readAll(_ handle: FileHandle) async throws -> Data {
        try await Task.detached { try handle.readToEnd() ?? Data() }.value
    }

    private nonisolated static func waitForExit(_ process: Process) async {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                process.waitUntilExit()
                continuation.resume()
            }
        }
    }
}

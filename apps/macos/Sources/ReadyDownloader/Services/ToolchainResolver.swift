import Foundation

struct Toolchain: Sendable {
    let ytDlp: URL
    let deno: URL
    let ffmpeg: URL
    let ffprobe: URL
}

struct ToolchainResolver: Sendable {
    private let overrideDirectory: String?
    private let resourceURL: URL?
    private let executableURL: URL?
    private let currentDirectory: URL

    init(
        overrideDirectory: String? = ProcessInfo.processInfo.environment["YTDLP_DOWNLOADER_TOOLS_DIR"],
        resourceURL: URL? = Bundle.main.resourceURL,
        executableURL: URL? = Bundle.main.executableURL,
        currentDirectory: URL = URL(
            filePath: FileManager.default.currentDirectoryPath,
            directoryHint: .isDirectory
        )
    ) {
        self.overrideDirectory = overrideDirectory
        self.resourceURL = resourceURL
        self.executableURL = executableURL
        self.currentDirectory = currentDirectory
    }

    func resolve() -> Toolchain {
        let directory = toolsDirectory()
        return Toolchain(
            ytDlp: directory.appending(path: "yt-dlp"),
            deno: directory.appending(path: "deno"),
            ffmpeg: directory.appending(path: "ffmpeg"),
            ffprobe: directory.appending(path: "ffprobe")
        )
    }

    func missingQueryTools(in toolchain: Toolchain) -> [URL] {
        [toolchain.ytDlp, toolchain.deno].filter { !isExecutable($0) }
    }

    func missingDownloadTools(in toolchain: Toolchain) -> [URL] {
        [toolchain.ytDlp, toolchain.deno, toolchain.ffmpeg, toolchain.ffprobe]
            .filter { !isExecutable($0) }
    }

    private func toolsDirectory() -> URL {
        if let override = overrideDirectory, !override.isEmpty {
            return URL(filePath: override, directoryHint: .isDirectory)
        }

        let bundledDirectory = resourceURL?.appending(path: "tools", directoryHint: .isDirectory)
        if let bundledDirectory, hasQueryTools(in: bundledDirectory) {
            return bundledDirectory
        }

        for origin in [executableURL?.deletingLastPathComponent(), currentDirectory].compactMap({ $0 }) {
            var directory = origin
            for _ in 0..<8 {
                let candidate = directory.appending(path: "tools/macos-arm64", directoryHint: .isDirectory)
                if hasQueryTools(in: candidate) { return candidate }
                let parent = directory.deletingLastPathComponent()
                if parent == directory { break }
                directory = parent
            }
        }

        return bundledDirectory
            ?? currentDirectory.appending(path: "tools/macos-arm64", directoryHint: .isDirectory)
    }

    private func hasQueryTools(in directory: URL) -> Bool {
        isExecutable(directory.appending(path: "yt-dlp"))
            && isExecutable(directory.appending(path: "deno"))
    }

    private func isExecutable(_ url: URL) -> Bool {
        FileManager.default.isExecutableFile(atPath: url.path)
    }
}

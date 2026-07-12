import Foundation

struct Toolchain: Sendable {
    let ytDlp: URL
    let deno: URL
    let ffmpeg: URL
    let ffprobe: URL
}

struct ToolchainResolver: Sendable {
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
        if let override = ProcessInfo.processInfo.environment["YTDLP_DOWNLOADER_TOOLS_DIR"], !override.isEmpty {
            return URL(filePath: override, directoryHint: .isDirectory)
        }
        if let resourceURL = Bundle.main.resourceURL {
            return resourceURL.appending(path: "tools", directoryHint: .isDirectory)
        }
        return URL(filePath: FileManager.default.currentDirectoryPath, directoryHint: .isDirectory)
            .appending(path: "tools/macos-arm64", directoryHint: .isDirectory)
    }

    private func isExecutable(_ url: URL) -> Bool {
        FileManager.default.isExecutableFile(atPath: url.path)
    }
}

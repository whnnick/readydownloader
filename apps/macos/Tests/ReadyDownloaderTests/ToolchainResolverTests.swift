import Foundation
import XCTest
@testable import ReadyDownloader

final class ToolchainResolverTests: XCTestCase {
    func testPrefersBundledTools() throws {
        let root = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let resources = root.appending(path: "App.app/Contents/Resources", directoryHint: .isDirectory)
        let bundledTools = resources.appending(path: "tools", directoryHint: .isDirectory)
        try makeQueryTools(in: bundledTools)

        let toolchain = ToolchainResolver(
            overrideDirectory: nil,
            resourceURL: resources,
            executableURL: root.appending(path: "App.app/Contents/MacOS/App"),
            currentDirectory: root
        ).resolve()

        XCTAssertEqual(toolchain.ytDlp, bundledTools.appending(path: "yt-dlp"))
        XCTAssertEqual(toolchain.deno, bundledTools.appending(path: "deno"))
    }

    func testFindsRepositoryTools() throws {
        let root = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let repositoryTools = root.appending(path: "tools/macos-arm64", directoryHint: .isDirectory)
        try makeQueryTools(in: repositoryTools)
        let executable = root.appending(path: "apps/macos/.build/arm64-apple-macosx/debug/App")

        let toolchain = ToolchainResolver(
            overrideDirectory: nil,
            resourceURL: root.appending(path: "missing-resources"),
            executableURL: executable,
            currentDirectory: root.appending(path: "apps/macos")
        ).resolve()

        XCTAssertEqual(toolchain.ytDlp, repositoryTools.appending(path: "yt-dlp"))
        XCTAssertEqual(toolchain.deno, repositoryTools.appending(path: "deno"))
    }

    private func temporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "ToolchainResolverTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func makeQueryTools(in directory: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        for name in ["yt-dlp", "deno"] {
            let file = directory.appending(path: name)
            try Data("test".utf8).write(to: file)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: file.path)
        }
    }
}

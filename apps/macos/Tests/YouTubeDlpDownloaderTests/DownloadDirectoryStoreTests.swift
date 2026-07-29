import Foundation
import Testing
@testable import YouTubeDlpDownloader

@Suite("Download directory store")
@MainActor
struct DownloadDirectoryStoreTests {
    @Test("Restores a saved path when a development bookmark is invalid")
    func restoresPathFallback() throws {
        let suiteName = "DownloadDirectoryStoreTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let directory = FileManager.default.temporaryDirectory
            .appending(path: "ytdlp-directory-store-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        defaults.set(Data("invalid bookmark".utf8), forKey: "downloadDirectoryBookmark")
        defaults.set(directory.path, forKey: "downloadDirectoryPath")

        let restored = DownloadDirectoryStore(defaults: defaults).currentDirectory()

        #expect(restored.standardizedFileURL == directory.standardizedFileURL)
    }

    @Test("Ignores a saved path that no longer exists")
    func ignoresMissingPathFallback() throws {
        let suiteName = "DownloadDirectoryStoreTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let missingDirectory = FileManager.default.temporaryDirectory
            .appending(path: "missing-ytdlp-directory-\(UUID().uuidString)", directoryHint: .isDirectory)
        defaults.set(Data("invalid bookmark".utf8), forKey: "downloadDirectoryBookmark")
        defaults.set(missingDirectory.path, forKey: "downloadDirectoryPath")

        let restored = DownloadDirectoryStore(defaults: defaults).currentDirectory()

        #expect(restored.standardizedFileURL != missingDirectory.standardizedFileURL)
    }
}

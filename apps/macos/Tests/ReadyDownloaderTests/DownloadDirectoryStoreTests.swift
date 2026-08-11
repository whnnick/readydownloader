import Foundation
import XCTest
@testable import ReadyDownloader

@MainActor
final class DownloadDirectoryStoreTests: XCTestCase {
    func testRestoresPathFallback() throws {
        let suiteName = "DownloadDirectoryStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let directory = FileManager.default.temporaryDirectory
            .appending(path: "ytdlp-directory-store-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        defaults.set(Data("invalid bookmark".utf8), forKey: "downloadDirectoryBookmark")
        defaults.set(directory.path, forKey: "downloadDirectoryPath")

        let restored = DownloadDirectoryStore(defaults: defaults).currentDirectory()

        XCTAssertEqual(restored.standardizedFileURL, directory.standardizedFileURL)
    }

    func testIgnoresMissingPathFallback() throws {
        let suiteName = "DownloadDirectoryStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let missingDirectory = FileManager.default.temporaryDirectory
            .appending(path: "missing-ytdlp-directory-\(UUID().uuidString)", directoryHint: .isDirectory)
        defaults.set(Data("invalid bookmark".utf8), forKey: "downloadDirectoryBookmark")
        defaults.set(missingDirectory.path, forKey: "downloadDirectoryPath")

        let restored = DownloadDirectoryStore(defaults: defaults).currentDirectory()

        XCTAssertNotEqual(restored.standardizedFileURL, missingDirectory.standardizedFileURL)
    }
}

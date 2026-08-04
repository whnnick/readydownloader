import AppKit
import Foundation

@MainActor
struct DownloadDirectoryStore {
    private static let bookmarkKey = "downloadDirectoryBookmark"
    private static let pathKey = "downloadDirectoryPath"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func currentDirectory() -> URL {
        if let data = defaults.data(forKey: Self.bookmarkKey) {
            var isStale = false
            if let url = try? URL(
                resolvingBookmarkData: data,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            ), isExistingDirectory(url) {
                if isStale { save(url) }
                return url
            }
        }

        if let path = defaults.string(forKey: Self.pathKey) {
            let url = URL(filePath: path, directoryHint: .isDirectory)
            if isExistingDirectory(url) { return url }
        }

        return defaultDirectory()
    }

    func chooseDirectory(language: AppLanguage) -> URL? {
        let panel = NSOpenPanel()
        panel.title = language.text("选择下载文件夹", "Choose Download Folder")
        panel.prompt = language.text("选择", "Choose")
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.directoryURL = currentDirectory()

        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        save(url)
        return url
    }

    func reveal(_ fileURL: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([fileURL])
    }

    private func save(_ url: URL) {
        defaults.set(url.path, forKey: Self.pathKey)
        guard let data = try? url.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ) else { return }
        defaults.set(data, forKey: Self.bookmarkKey)
    }

    private func defaultDirectory() -> URL {
        FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
            ?? URL(filePath: NSHomeDirectory(), directoryHint: .isDirectory)
    }

    private func isExistingDirectory(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
            && isDirectory.boolValue
    }
}

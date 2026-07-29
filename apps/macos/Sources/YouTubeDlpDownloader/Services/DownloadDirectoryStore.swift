import AppKit
import Foundation

@MainActor
struct DownloadDirectoryStore {
    private static let bookmarkKey = "downloadDirectoryBookmark"

    func currentDirectory() -> URL {
        guard let data = UserDefaults.standard.data(forKey: Self.bookmarkKey) else {
            return defaultDirectory()
        }

        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: data,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else {
            return defaultDirectory()
        }

        if isStale { save(url) }
        return url
    }

    func chooseDirectory() -> URL? {
        let panel = NSOpenPanel()
        panel.title = "Choose Download Folder"
        panel.prompt = "Choose"
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
        guard let data = try? url.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ) else { return }
        UserDefaults.standard.set(data, forKey: Self.bookmarkKey)
    }

    private func defaultDirectory() -> URL {
        FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
            ?? URL(filePath: NSHomeDirectory(), directoryHint: .isDirectory)
    }
}

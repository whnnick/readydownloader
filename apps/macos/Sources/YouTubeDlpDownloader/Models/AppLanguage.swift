import Foundation

enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case simplifiedChinese
    case english

    static let storageKey = "appLanguage"

    var id: Self { self }

    var displayName: String {
        switch self {
        case .simplifiedChinese: "简体中文"
        case .english: "English"
        }
    }

    func text(_ chinese: String, _ english: String) -> String {
        switch self {
        case .simplifiedChinese: chinese
        case .english: english
        }
    }

    static var current: AppLanguage {
        guard let value = UserDefaults.standard.string(forKey: storageKey),
              let language = AppLanguage(rawValue: value) else {
            return .simplifiedChinese
        }
        return language
    }
}

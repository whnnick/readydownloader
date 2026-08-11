import Foundation

enum NetworkMode: String, CaseIterable, Identifiable, Sendable {
    case direct
    case system
    case custom

    var id: Self { self }

    func title(language: AppLanguage) -> String {
        switch self {
        case .direct: language.text("直接连接", "Direct")
        case .system: language.text("跟随系统", "System Proxy")
        case .custom: language.text("自定义代理", "Custom Proxy")
        }
    }
}

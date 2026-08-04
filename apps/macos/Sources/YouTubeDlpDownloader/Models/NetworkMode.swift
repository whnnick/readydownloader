import Foundation

enum NetworkMode: String, CaseIterable, Identifiable, Sendable {
    case direct
    case system
    case custom

    var id: Self { self }

    var title: String {
        switch self {
        case .direct: "直接连接"
        case .system: "跟随系统"
        case .custom: "自定义代理"
        }
    }
}

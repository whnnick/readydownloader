import Foundation

enum NetworkMode: String, CaseIterable, Identifiable, Sendable {
    case direct
    case system
    case custom

    var id: Self { self }

    var title: String {
        switch self {
        case .direct: "Direct"
        case .system: "System Proxy"
        case .custom: "Custom Proxy"
        }
    }
}

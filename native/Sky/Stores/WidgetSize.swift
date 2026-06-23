import Foundation

/// Discrete widget tile size, mirroring Apple's WidgetFamily (small/medium/large).
enum WidgetSize: String, Codable, CaseIterable, Sendable {
    case small, medium, large

    var cols: Int { self == .small ? 1 : 2 }
    var rows: Int { self == .large ? 2 : 1 }
}

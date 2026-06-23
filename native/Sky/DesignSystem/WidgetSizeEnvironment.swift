import SwiftUI

/// Environment key exposing the discrete widget size to child views,
/// mirroring Apple's `@Environment(\.widgetFamily)`.
private struct WidgetSizeKey: EnvironmentKey {
    static let defaultValue: WidgetSize = .small
}

extension EnvironmentValues {
    var widgetSize: WidgetSize {
        get { self[WidgetSizeKey.self] }
        set { self[WidgetSizeKey.self] = newValue }
    }
}

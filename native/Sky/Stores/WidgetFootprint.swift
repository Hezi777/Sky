/// Per-widget grid footprint: how many columns and rows the widget occupies
/// in the editable grid layout.
struct WidgetFootprint: Codable, Equatable, Sendable {
    var cols: Int   // 1...Tokens.dashboardGridMaxColumns
    var rows: Int   // 1...WidgetFootprint.maxRows

    static let maxRows = 4
    static let regular = WidgetFootprint(cols: 1, rows: 1)
    static let wide = WidgetFootprint(cols: 2, rows: 1)

    func clamped(maxCols: Int) -> WidgetFootprint {
        WidgetFootprint(
            cols: max(1, min(cols, maxCols)),
            rows: max(1, min(rows, Self.maxRows))
        )
    }
}

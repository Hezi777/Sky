import SwiftUI

/// Transient edit-mode state for the dashboard grid. Owns drag/resize tracking
/// and the cell-rect map used for hit-testing during reorder. Not persisted.
@MainActor @Observable
final class DashboardEditState {
    var isEditing = false
    var draggedKind: WidgetKind?
    var dragTranslation: CGSize = .zero
    var resizingKind: WidgetKind?
    var previewFootprint: WidgetFootprint?
    var cellRects: [WidgetKind: CGRect] = [:]
}

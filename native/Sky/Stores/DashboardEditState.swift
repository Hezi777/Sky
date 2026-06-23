import SwiftUI

/// Transient edit-mode state for the dashboard grid. Owns drag tracking
/// and the cell-rect map used for hit-testing during reorder. Not persisted.
@MainActor @Observable
final class DashboardEditState {
    var isEditing = false
    var draggedKind: WidgetKind?
    var dragTranslation: CGSize = .zero
    var cellRects: [WidgetKind: CGRect] = [:]
}

import SwiftUI

// MARK: - Layout value keys

/// Carries each child's grid footprint (cols × rows).
struct WidgetFootprintKey: LayoutValueKey {
    static let defaultValue = WidgetFootprint.regular
}

/// Per-child transient drag offset applied during edit-mode reordering.
/// Only the actively dragged card gets a non-zero value (set by the parent view).
struct WidgetDragOffsetKey: LayoutValueKey {
    static let defaultValue: CGSize = .zero
}

// MARK: - Grid layout

/// Fixed-cell 2D grid layout for dashboard widgets. Each child declares a
/// `WidgetFootprint` (cols × rows); placement uses dense shortest-column
/// packing. Height is deterministic from the row count — children clip or
/// scroll internally.
struct GridDashboardLayout: Layout {

    private struct Placement {
        let index: Int
        let origin: CGPoint
        let size: CGSize
        let dragOffset: CGSize
    }

    // MARK: Layout protocol

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let width = proposal.width ?? naturalWidth(for: subviews)
        let result = placements(for: subviews, width: width)
        return CGSize(width: width, height: result.height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> Void {
        for placement in placements(for: subviews, width: bounds.width).items {
            let origin = CGPoint(
                x: bounds.minX + placement.origin.x + placement.dragOffset.width,
                y: bounds.minY + placement.origin.y + placement.dragOffset.height
            )
            subviews[placement.index].place(
                at: origin,
                anchor: .topLeading,
                proposal: ProposedViewSize(placement.size)
            )
        }
    }

    // MARK: Packing

    private func placements(
        for subviews: Subviews,
        width: CGFloat
    ) -> (items: [Placement], height: CGFloat) {
        let estimatedColumns = Int(
            (width + Tokens.cardGap) / (Tokens.dashboardGridTarget + Tokens.cardGap)
        )
        let columnCount = width < Tokens.dashboardGridBreakpoint
            ? 1
            : min(Tokens.dashboardGridMaxColumns, max(1, estimatedColumns))
        let columnWidth = max(
            Tokens.dashboardGridMinimum,
            (width - CGFloat(columnCount - 1) * Tokens.cardGap) / CGFloat(columnCount)
        )

        var items: [Placement] = []
        var columnHeights = Array(repeating: CGFloat.zero, count: columnCount)

        for index in subviews.indices {
            let subview = subviews[index]
            let footprint = subview[WidgetFootprintKey.self]
            let colSpan = min(footprint.cols, columnCount)
            let column = shortestRangeStart(span: colSpan, heights: columnHeights)
            let y = columnHeights[column..<(column + colSpan)].max() ?? 0

            let itemWidth = CGFloat(colSpan) * columnWidth + CGFloat(colSpan - 1) * Tokens.cardGap
            let itemHeight = CGFloat(footprint.rows) * Tokens.dashboardRowUnit
                + CGFloat(footprint.rows - 1) * Tokens.cardGap
            let x = CGFloat(column) * (columnWidth + Tokens.cardGap)

            let dragOffset = subview[WidgetDragOffsetKey.self]
            items.append(Placement(
                index: index,
                origin: CGPoint(x: x, y: y),
                size: CGSize(width: itemWidth, height: itemHeight),
                dragOffset: dragOffset
            ))

            let nextY = y + itemHeight + Tokens.cardGap
            for occupiedColumn in column..<(column + colSpan) {
                columnHeights[occupiedColumn] = nextY
            }
        }

        let maxHeight = columnHeights.max() ?? 0
        return (items, maxHeight > 0 ? maxHeight - Tokens.cardGap : 0)
    }

    // MARK: Shortest-range start (dense packing with void tiebreak)

    private func shortestRangeStart(span: Int, heights: [CGFloat]) -> Int {
        guard span <= heights.count else { return 0 }

        return (0...(heights.count - span)).min { lhs, rhs in
            let lhsHeight = heights[lhs..<(lhs + span)].max() ?? 0
            let rhsHeight = heights[rhs..<(rhs + span)].max() ?? 0
            if lhsHeight == rhsHeight {
                let lhsVoid = heights[lhs..<(lhs + span)].reduce(0) { lhsHeight - $1 + $0 }
                let rhsVoid = heights[rhs..<(rhs + span)].reduce(0) { rhsHeight - $1 + $0 }
                if lhsVoid == rhsVoid { return lhs < rhs }
                return lhsVoid < rhsVoid
            }
            return lhsHeight < rhsHeight
        } ?? 0
    }

    private func naturalWidth(for subviews: Subviews) -> CGFloat {
        subviews.map { $0.sizeThatFits(.unspecified).width }.max() ?? Tokens.dashboardGridMinimum
    }
}

// MARK: - Preview

#Preview("GridDashboardLayout") {
    ScrollView {
        GridDashboardLayout {
            // 1×1 regular
            RoundedRectangle(cornerRadius: Tokens.cardRadius)
                .fill(.blue.opacity(0.3))
                .layoutValue(key: WidgetFootprintKey.self, value: .regular)

            // 2×1 wide
            RoundedRectangle(cornerRadius: Tokens.cardRadius)
                .fill(.green.opacity(0.3))
                .layoutValue(key: WidgetFootprintKey.self, value: .wide)

            // 1×2 tall
            RoundedRectangle(cornerRadius: Tokens.cardRadius)
                .fill(.orange.opacity(0.3))
                .layoutValue(
                    key: WidgetFootprintKey.self,
                    value: WidgetFootprint(cols: 1, rows: 2)
                )

            // 2×2 large
            RoundedRectangle(cornerRadius: Tokens.cardRadius)
                .fill(.purple.opacity(0.3))
                .layoutValue(
                    key: WidgetFootprintKey.self,
                    value: WidgetFootprint(cols: 2, rows: 2)
                )

            // 1×1 regular (trailing filler)
            RoundedRectangle(cornerRadius: Tokens.cardRadius)
                .fill(.red.opacity(0.3))
                .layoutValue(key: WidgetFootprintKey.self, value: .regular)
        }
    }
    .padding(Tokens.gap)
}

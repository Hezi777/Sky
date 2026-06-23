import SwiftUI

// MARK: - Layout value keys

/// Carries each child's discrete grid size (cols × rows).
struct WidgetSizeLayoutKey: LayoutValueKey {
    static let defaultValue: WidgetSize = .small
}

/// Per-child transient drag offset applied during edit-mode reordering.
/// Only the actively dragged card gets a non-zero value (set by the parent view).
struct WidgetDragOffsetKey: LayoutValueKey {
    static let defaultValue: CGSize = .zero
}

// MARK: - Grid layout

/// Fixed-cell 2D grid layout for dashboard widgets. Each child declares a
/// `WidgetSize` (cols × rows via discrete enum); placement uses a dense
/// 2D occupancy-grid packer that guarantees no overlap.
struct GridDashboardLayout: Layout {

    private struct Placement {
        let index: Int
        let col: Int
        let row: Int
        let colSpan: Int
        let rowSpan: Int
        let dragOffset: CGSize
    }

    // MARK: Layout protocol

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let width = proposal.width ?? naturalWidth(for: subviews)
        let result = pack(subviews: subviews, width: width)
        return CGSize(width: width, height: result.height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> Void {
        let result = pack(subviews: subviews, width: bounds.width)
        let columnCount = result.columnCount
        let cellWidth = max(
            Tokens.dashboardGridMinimum,
            (bounds.width - CGFloat(columnCount - 1) * Tokens.cardGap) / CGFloat(columnCount)
        )

        for placement in result.items {
            let itemWidth = CGFloat(placement.colSpan) * cellWidth
                + CGFloat(placement.colSpan - 1) * Tokens.cardGap
            let itemHeight = CGFloat(placement.rowSpan) * Tokens.dashboardRowUnit
                + CGFloat(placement.rowSpan - 1) * Tokens.cardGap
            let x = CGFloat(placement.col) * (cellWidth + Tokens.cardGap)
            let y = CGFloat(placement.row) * (Tokens.dashboardRowUnit + Tokens.cardGap)

            let origin = CGPoint(
                x: bounds.minX + x + placement.dragOffset.width,
                y: bounds.minY + y + placement.dragOffset.height
            )
            subviews[placement.index].place(
                at: origin,
                anchor: .topLeading,
                proposal: ProposedViewSize(width: itemWidth, height: itemHeight)
            )
        }
    }

    // MARK: - 2D occupancy-grid packer

    private struct PackResult {
        let items: [Placement]
        let height: CGFloat
        let columnCount: Int
    }

    private func pack(subviews: Subviews, width: CGFloat) -> PackResult {
        let estimatedColumns = Int(
            (width + Tokens.cardGap) / (Tokens.dashboardGridTarget + Tokens.cardGap)
        )
        let columnCount: Int
        if width < Tokens.dashboardGridBreakpoint {
            columnCount = 1
        } else {
            columnCount = min(Tokens.dashboardGridMaxColumns, max(1, estimatedColumns))
        }

        // 2D boolean occupancy grid, grows rows as needed.
        var occupied: [[Bool]] = []
        var items: [Placement] = []
        var maxRowEnd = 0

        for index in subviews.indices {
            let subview = subviews[index]
            let size = subview[WidgetSizeLayoutKey.self]
            let colSpan = min(size.cols, columnCount)
            let rowSpan = size.rows
            let dragOffset = subview[WidgetDragOffsetKey.self]

            // Find first available position row-major.
            let position = findPosition(
                colSpan: colSpan,
                rowSpan: rowSpan,
                columnCount: columnCount,
                occupied: &occupied
            )

            // Mark cells occupied.
            for r in position.row..<(position.row + rowSpan) {
                for c in position.col..<(position.col + colSpan) {
                    occupied[r][c] = true
                }
            }

            items.append(Placement(
                index: index,
                col: position.col,
                row: position.row,
                colSpan: colSpan,
                rowSpan: rowSpan,
                dragOffset: dragOffset
            ))

            maxRowEnd = max(maxRowEnd, position.row + rowSpan)
        }

        let height: CGFloat
        if maxRowEnd > 0 {
            height = CGFloat(maxRowEnd) * Tokens.dashboardRowUnit
                + CGFloat(maxRowEnd - 1) * Tokens.cardGap
        } else {
            height = 0
        }

        return PackResult(items: items, height: height, columnCount: columnCount)
    }

    /// Scans the occupancy grid row-major for the first position where a
    /// `colSpan × rowSpan` block fits. Grows the grid as needed.
    private func findPosition(
        colSpan: Int,
        rowSpan: Int,
        columnCount: Int,
        occupied: inout [[Bool]]
    ) -> (row: Int, col: Int) {
        var row = 0
        while true {
            // Ensure enough rows exist.
            while occupied.count < row + rowSpan {
                occupied.append(Array(repeating: false, count: columnCount))
            }

            for col in 0...(columnCount - colSpan) {
                if regionIsFree(row: row, col: col, rowSpan: rowSpan, colSpan: colSpan, occupied: occupied) {
                    return (row, col)
                }
            }
            row += 1
        }
    }

    private func regionIsFree(
        row: Int, col: Int, rowSpan: Int, colSpan: Int, occupied: [[Bool]]
    ) -> Bool {
        for r in row..<(row + rowSpan) {
            for c in col..<(col + colSpan) {
                if occupied[r][c] { return false }
            }
        }
        return true
    }

    private func naturalWidth(for subviews: Subviews) -> CGFloat {
        subviews.map { $0.sizeThatFits(.unspecified).width }.max() ?? Tokens.dashboardGridMinimum
    }
}

// MARK: - Preview

#Preview("GridDashboardLayout") {
    ScrollView {
        GridDashboardLayout {
            // small (1×1)
            RoundedRectangle(cornerRadius: Tokens.cardRadius)
                .fill(.blue.opacity(0.3))
                .overlay(Text("small"))
                .layoutValue(key: WidgetSizeLayoutKey.self, value: .small)

            // medium (2×1)
            RoundedRectangle(cornerRadius: Tokens.cardRadius)
                .fill(.green.opacity(0.3))
                .overlay(Text("medium"))
                .layoutValue(key: WidgetSizeLayoutKey.self, value: .medium)

            // small (1×1)
            RoundedRectangle(cornerRadius: Tokens.cardRadius)
                .fill(.orange.opacity(0.3))
                .overlay(Text("small"))
                .layoutValue(key: WidgetSizeLayoutKey.self, value: .small)

            // large (2×2)
            RoundedRectangle(cornerRadius: Tokens.cardRadius)
                .fill(.purple.opacity(0.3))
                .overlay(Text("large"))
                .layoutValue(key: WidgetSizeLayoutKey.self, value: .large)

            // small (1×1) — filler
            RoundedRectangle(cornerRadius: Tokens.cardRadius)
                .fill(.red.opacity(0.3))
                .overlay(Text("small"))
                .layoutValue(key: WidgetSizeLayoutKey.self, value: .small)

            // medium (2×1)
            RoundedRectangle(cornerRadius: Tokens.cardRadius)
                .fill(.cyan.opacity(0.3))
                .overlay(Text("medium"))
                .layoutValue(key: WidgetSizeLayoutKey.self, value: .medium)
        }
    }
    .padding(Tokens.gap)
}

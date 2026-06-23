import SwiftUI

/// Edit-mode chrome overlaid on each widget cell. Shows drag grip, hide button,
/// and resize handle. Returns `EmptyView` when not editing so widget identity
/// and @State are preserved (overlay, not wrapper).
struct EditChromeOverlay: View {
    let kind: WidgetKind

    @Environment(DashboardEditState.self) private var editState
    @Environment(DashboardConfig.self) private var config
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if editState.isEditing {
            editOverlay
        }
    }

    // MARK: - Edit overlay

    private var editOverlay: some View {
        RoundedRectangle(cornerRadius: Tokens.cardRadius, style: .continuous)
            .fill(.ultraThinMaterial.opacity(0.3))
            .overlay(
                RoundedRectangle(cornerRadius: Tokens.cardRadius, style: .continuous)
                    .strokeBorder(Tokens.accent.opacity(0.4), lineWidth: Tokens.cardStrokeWidth * 2)
            )
            .overlay(alignment: .topLeading) { dragGrip }
            .overlay(alignment: .topTrailing) { hideButton }
            .overlay(alignment: .bottomTrailing) { resizeHandle }
            .allowsHitTesting(true)
    }

    // MARK: - Drag grip

    private var dragGrip: some View {
        Image(systemName: "line.3.horizontal")
            .font(.system(size: Tokens.Size.compactControl, weight: .medium))
            .foregroundStyle(.secondary)
            .padding(Tokens.snug)
            .contentShape(Rectangle())
            .gesture(dragGesture)
            .accessibilityLabel("Reorder \(kind.title)")
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: Tokens.snug)
            .onChanged { value in
                editState.draggedKind = kind
                editState.dragTranslation = value.translation
                reorderHitTest(translation: value.translation)
            }
            .onEnded { _ in
                withAnimation(editAnimation) {
                    editState.draggedKind = nil
                    editState.dragTranslation = .zero
                }
            }
    }

    // MARK: - Hide button

    private var hideButton: some View {
        Button {
            withAnimation(editAnimation) {
                config.toggle(kind)
            }
        } label: {
            Image(systemName: "eye.slash")
                .font(.system(size: Tokens.Size.compactControl, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(Tokens.snug)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Hide \(kind.title)")
    }

    // MARK: - Resize handle

    private var resizeHandle: some View {
        Image(systemName: "arrow.down.right.and.arrow.up.left")
            .font(.system(size: Tokens.Size.compactControl, weight: .medium))
            .foregroundStyle(.secondary)
            .padding(Tokens.snug)
            .contentShape(Rectangle())
            .gesture(resizeGesture)
            .accessibilityLabel("Resize \(kind.title)")
    }

    private var resizeGesture: some Gesture {
        DragGesture(minimumDistance: Tokens.tight)
            .onChanged { value in
                editState.resizingKind = kind
                let currentFootprint = config.footprint(for: kind)
                let cellWidth = estimatedColumnWidth
                let cellHeight = Tokens.dashboardRowUnit

                let dCols = Int((value.translation.width / (cellWidth + Tokens.cardGap)).rounded())
                let dRows = Int((value.translation.height / (cellHeight + Tokens.cardGap)).rounded())

                let newFootprint = WidgetFootprint(
                    cols: currentFootprint.cols + dCols,
                    rows: currentFootprint.rows + dRows
                ).clamped(maxCols: Tokens.dashboardGridMaxColumns)

                editState.previewFootprint = newFootprint
            }
            .onEnded { _ in
                if let preview = editState.previewFootprint {
                    withAnimation(editAnimation) {
                        config.setFootprint(kind, cols: preview.cols, rows: preview.rows)
                    }
                }
                editState.resizingKind = nil
                editState.previewFootprint = nil
            }
    }

    // MARK: - Reorder hit-testing

    /// Finds the card under the dragged card's displaced center and swaps order.
    private func reorderHitTest(translation: CGSize) {
        guard let sourceRect = editState.cellRects[kind] else { return }
        let center = CGPoint(
            x: sourceRect.midX + translation.width,
            y: sourceRect.midY + translation.height
        )
        for (targetKind, targetRect) in editState.cellRects where targetKind != kind {
            if targetRect.contains(center) {
                guard let sourceIndex = config.order.firstIndex(of: kind),
                      let targetIndex = config.order.firstIndex(of: targetKind)
                else { return }
                if sourceIndex != targetIndex {
                    withAnimation(editAnimation) {
                        config.order.move(
                            fromOffsets: IndexSet(integer: sourceIndex),
                            toOffset: targetIndex > sourceIndex ? targetIndex + 1 : targetIndex
                        )
                    }
                }
                return
            }
        }
    }

    // MARK: - Helpers

    private var editAnimation: Animation {
        reduceMotion
            ? .easeInOut(duration: 0.15)
            : .spring(duration: 0.35, bounce: 0.15)
    }

    /// Estimate column width from this card's rect and its current footprint cols.
    private var estimatedColumnWidth: CGFloat {
        guard let rect = editState.cellRects[kind] else {
            return Tokens.dashboardGridTarget
        }
        let currentCols = CGFloat(config.footprint(for: kind).cols)
        return (rect.width - (currentCols - 1) * Tokens.cardGap) / currentCols
    }
}

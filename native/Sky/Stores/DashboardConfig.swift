import SwiftUI
import Observation

// Persisted dashboard preferences: which widgets show, in what order, plus the
// user's name. Stored as JSON in UserDefaults (single-user, no backend needed).

@Observable
final class DashboardConfig {
    var name: String { didSet { persist() } }
    var order: [WidgetKind] { didSet { persist() } }
    var hidden: Set<WidgetKind> { didSet { persist() } }
    var footprints: [WidgetKind: WidgetFootprint] { didSet { persist() } }

    private static let key = "sky.dashboard.config.v2"
    private static let legacyKey = "sky.dashboard.config.v1"

    init() {
        if let saved = Self.load() {
            name = saved.name
            order = saved.order
            hidden = saved.hidden
            footprints = saved.footprints
        } else if let legacy = Self.loadLegacy() {
            // Migrate v1 → v2: preserve user order/hidden, synthesize footprints.
            name = legacy.name
            order = legacy.order
            hidden = legacy.hidden
            footprints = Dictionary(
                uniqueKeysWithValues: WidgetKind.allCases.map { ($0, $0.defaultFootprint) }
            )
        } else {
            name = "Hen"
            order = DashboardSectionSpec.defaultOrder
            hidden = Set(WidgetKind.allCases.filter { !$0.defaultVisible })
            footprints = Dictionary(
                uniqueKeysWithValues: WidgetKind.allCases.map { ($0, $0.defaultFootprint) }
            )
        }
    }

    /// Widgets to render, in order, excluding hidden ones.
    var visibleWidgets: [WidgetKind] {
        order.filter { !hidden.contains($0) }
    }

    func isVisible(_ kind: WidgetKind) -> Bool { !hidden.contains(kind) }

    func toggle(_ kind: WidgetKind) {
        if hidden.contains(kind) { hidden.remove(kind) } else { hidden.insert(kind) }
    }

    func move(from source: IndexSet, to destination: Int) {
        order.move(fromOffsets: source, toOffset: destination)
    }

    // MARK: - Footprint helpers

    /// Current footprint for a widget, falling back to its default. Always
    /// clamped so a corrupt persisted value can't overflow the grid or yield a
    /// zero span (which would divide-by-zero in the resize estimator).
    func footprint(for kind: WidgetKind) -> WidgetFootprint {
        (footprints[kind] ?? kind.defaultFootprint).clamped(maxCols: Tokens.dashboardGridMaxColumns)
    }

    func setFootprint(_ kind: WidgetKind, cols: Int, rows: Int) {
        footprints[kind] = WidgetFootprint(cols: cols, rows: rows)
            .clamped(maxCols: Tokens.dashboardGridMaxColumns)
    }

    func adjustFootprint(_ kind: WidgetKind, dCols: Int, dRows: Int) {
        let current = footprint(for: kind)
        setFootprint(kind, cols: current.cols + dCols, rows: current.rows + dRows)
    }

    // MARK: - Reorder helpers

    func moveUp(_ kind: WidgetKind) {
        guard let idx = order.firstIndex(of: kind), idx > order.startIndex else { return }
        order.swapAt(idx, idx - 1)
    }

    func moveDown(_ kind: WidgetKind) {
        guard let idx = order.firstIndex(of: kind), idx < order.index(before: order.endIndex) else { return }
        order.swapAt(idx, idx + 1)
    }

    /// Restores the semantic default order, visibility, and footprints (Settings → Dashboard).
    func resetLayout() {
        order = DashboardSectionSpec.defaultOrder
        hidden = Set(WidgetKind.allCases.filter { !$0.defaultVisible })
        footprints = Dictionary(
            uniqueKeysWithValues: WidgetKind.allCases.map { ($0, $0.defaultFootprint) }
        )
    }

    // MARK: - Persistence

    private struct Snapshot: Codable {
        var name: String
        var order: [WidgetKind]
        var hidden: Set<WidgetKind>
        var footprints: [WidgetKind: WidgetFootprint]
    }

    /// Legacy v1 snapshot (no footprints) for migration.
    private struct LegacySnapshot: Codable {
        var name: String
        var order: [WidgetKind]
        var hidden: Set<WidgetKind>
    }

    private func persist() {
        let snap = Snapshot(name: name, order: order, hidden: hidden, footprints: footprints)
        if let data = try? JSONEncoder().encode(snap) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }

    private static func load() -> Snapshot? {
        guard let data = UserDefaults.standard.data(forKey: key),
              var snap = try? JSONDecoder().decode(Snapshot.self, from: data)
        else { return nil }
        // Append any widgets added in newer app versions so they aren't lost.
        let known = Set(snap.order)
        for kind in WidgetKind.allCases where !known.contains(kind) {
            snap.order.append(kind)
            if !kind.defaultVisible { snap.hidden.insert(kind) }
            snap.footprints[kind] = kind.defaultFootprint
        }
        if DashboardSectionSpec.legacyDefaultOrders.contains(snap.order) {
            snap.order = DashboardSectionSpec.defaultOrder
        }
        return snap
    }

    /// Load a v1 snapshot for migration (preserves user order/hidden).
    private static func loadLegacy() -> LegacySnapshot? {
        guard let data = UserDefaults.standard.data(forKey: legacyKey),
              var snap = try? JSONDecoder().decode(LegacySnapshot.self, from: data)
        else { return nil }
        let known = Set(snap.order)
        for kind in WidgetKind.allCases where !known.contains(kind) {
            snap.order.append(kind)
            if !kind.defaultVisible { snap.hidden.insert(kind) }
        }
        if DashboardSectionSpec.legacyDefaultOrders.contains(snap.order) {
            snap.order = DashboardSectionSpec.defaultOrder
        }
        return snap
    }
}

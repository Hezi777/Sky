import SwiftUI
import Observation

// Persisted dashboard preferences: which widgets show, in what order, plus the
// user's name. Stored as JSON in UserDefaults (single-user, no backend needed).

@Observable
final class DashboardConfig {
    var name: String { didSet { persist() } }
    var order: [WidgetKind] { didSet { persist() } }
    var hidden: Set<WidgetKind> { didSet { persist() } }
    var sizes: [WidgetKind: WidgetSize] { didSet { persist() } }

    private static let key = "sky.dashboard.config.v3"
    private static let legacyV2Key = "sky.dashboard.config.v2"
    private static let legacyV1Key = "sky.dashboard.config.v1"

    init() {
        if let saved = Self.load() {
            name = saved.name
            order = saved.order
            hidden = saved.hidden
            sizes = saved.sizes
        } else if let v2 = Self.loadV2() {
            // Migrate v2 → v3: convert footprints to discrete sizes.
            name = v2.name
            order = v2.order
            hidden = v2.hidden
            sizes = Self.convertFootprints(v2.footprints)
        } else if let v1 = Self.loadV1() {
            // Migrate v1 → v3: preserve order/hidden, synthesize default sizes.
            name = v1.name
            order = v1.order
            hidden = v1.hidden
            sizes = Dictionary(
                uniqueKeysWithValues: WidgetKind.allCases.map { ($0, $0.defaultSize) }
            )
        } else {
            name = "Hen"
            order = DashboardSectionSpec.defaultOrder
            hidden = Set(WidgetKind.allCases.filter { !$0.defaultVisible })
            sizes = Dictionary(
                uniqueKeysWithValues: WidgetKind.allCases.map { ($0, $0.defaultSize) }
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

    // MARK: - Size helpers

    /// Current size for a widget, validated against its supported sizes.
    func size(for kind: WidgetKind) -> WidgetSize {
        if let stored = sizes[kind], kind.supportedSizes.contains(stored) {
            return stored
        }
        return kind.defaultSize
    }

    func setSize(_ size: WidgetSize, for kind: WidgetKind) {
        guard kind.supportedSizes.contains(size) else { return }
        sizes[kind] = size
    }

    /// Advance to the next supported size (wraps around).
    func cycleSize(_ kind: WidgetKind) {
        let supported = kind.supportedSizes
        guard supported.count > 1 else { return }
        let current = size(for: kind)
        guard let idx = supported.firstIndex(of: current) else {
            sizes[kind] = supported[0]
            return
        }
        sizes[kind] = supported[(idx + 1) % supported.count]
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

    /// Restores the semantic default order, visibility, and sizes (Settings → Dashboard).
    func resetLayout() {
        order = DashboardSectionSpec.defaultOrder
        hidden = Set(WidgetKind.allCases.filter { !$0.defaultVisible })
        sizes = Dictionary(
            uniqueKeysWithValues: WidgetKind.allCases.map { ($0, $0.defaultSize) }
        )
    }

    // MARK: - Persistence

    private struct Snapshot: Codable {
        var name: String
        var order: [WidgetKind]
        var hidden: Set<WidgetKind>
        var sizes: [WidgetKind: WidgetSize]
    }

    /// Legacy v2 snapshot (footprints) for migration.
    private struct V2Snapshot: Codable {
        var name: String
        var order: [WidgetKind]
        var hidden: Set<WidgetKind>
        var footprints: [WidgetKind: V2Footprint]
    }

    /// Minimal footprint shape matching the deleted WidgetFootprint for decoding.
    private struct V2Footprint: Codable {
        var cols: Int
        var rows: Int
    }

    /// Legacy v1 snapshot (no footprints) for migration.
    private struct V1Snapshot: Codable {
        var name: String
        var order: [WidgetKind]
        var hidden: Set<WidgetKind>
    }

    private func persist() {
        let snap = Snapshot(name: name, order: order, hidden: hidden, sizes: sizes)
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
            snap.sizes[kind] = kind.defaultSize
        }
        // Fill any missing sizes.
        for kind in WidgetKind.allCases where snap.sizes[kind] == nil {
            snap.sizes[kind] = kind.defaultSize
        }
        if DashboardSectionSpec.legacyDefaultOrders.contains(snap.order) {
            snap.order = DashboardSectionSpec.defaultOrder
        }
        return snap
    }

    /// Load a v2 snapshot for migration (footprints → sizes).
    private static func loadV2() -> V2Snapshot? {
        guard let data = UserDefaults.standard.data(forKey: legacyV2Key),
              var snap = try? JSONDecoder().decode(V2Snapshot.self, from: data)
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

    /// Load a v1 snapshot for migration (preserves user order/hidden).
    private static func loadV1() -> V1Snapshot? {
        guard let data = UserDefaults.standard.data(forKey: legacyV1Key),
              var snap = try? JSONDecoder().decode(V1Snapshot.self, from: data)
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

    /// Convert v2 footprints to discrete sizes.
    private static func convertFootprints(_ footprints: [WidgetKind: V2Footprint]) -> [WidgetKind: WidgetSize] {
        var result: [WidgetKind: WidgetSize] = [:]
        for kind in WidgetKind.allCases {
            if let fp = footprints[kind] {
                let converted: WidgetSize
                switch (fp.cols, fp.rows) {
                case (1, 1): converted = .small
                case (2, 1): converted = .medium
                case (2, 2): converted = .large
                default: converted = kind.defaultSize
                }
                // Clamp to supported sizes.
                result[kind] = kind.supportedSizes.contains(converted) ? converted : kind.defaultSize
            } else {
                result[kind] = kind.defaultSize
            }
        }
        return result
    }
}

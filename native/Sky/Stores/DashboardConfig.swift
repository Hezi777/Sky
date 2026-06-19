import SwiftUI
import Observation

// Persisted dashboard preferences: which widgets show, in what order, plus the
// user's name. Stored as JSON in UserDefaults (single-user, no backend needed).

@Observable
final class DashboardConfig {
    var name: String { didSet { persist() } }
    var order: [WidgetKind] { didSet { persist() } }
    var hidden: Set<WidgetKind> { didSet { persist() } }

    private static let key = "sky.dashboard.config.v1"

    init() {
        if let saved = Self.load() {
            name = saved.name
            order = saved.order
            hidden = saved.hidden
        } else {
            name = "Hen"
            order = WidgetKind.allCases
            hidden = Set(WidgetKind.allCases.filter { !$0.defaultVisible })
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

    // MARK: - Persistence

    private struct Snapshot: Codable {
        var name: String
        var order: [WidgetKind]
        var hidden: Set<WidgetKind>
    }

    private func persist() {
        let snap = Snapshot(name: name, order: order, hidden: hidden)
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
        }
        return snap
    }
}

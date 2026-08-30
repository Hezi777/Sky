import SwiftUI

struct CountdownWidget: View {
    @Environment(\.widgetSize) private var size
    @State private var trips: [Trip] = DemoMode.isEnabled ? [DemoFixtures.trip] : Trip.loadAll()
    @State private var showEditor = false
    @State private var editingTrip: Trip?

    private var nextTrip: Trip? {
        let today = Calendar.current.startOfDay(for: .now)
        return trips
            .filter { $0.date >= today }
            .sorted { $0.date < $1.date }
            .first
    }

    var body: some View {
        WidgetShell(
            title: "Countdown",
            symbol: "airplane.departure",
            tint: Tokens.accent,
            accessory: {
                Button {
                    editingTrip = nil
                    showEditor = true
                } label: {
                    Image(systemName: "plus")
                        .font(Tokens.Font.badge)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Add trip")
                .help("Add trip")
            }
        ) {
            if let trip = nextTrip {
                TripCountdownView(trip: trip, size: size) {
                    editingTrip = trip
                    showEditor = true
                }
            } else {
                EmptyHint(text: "No upcoming trips — tap + to add one")
            }
        }
        .sheet(isPresented: $showEditor) {
            TripEditor(trip: editingTrip) { saved in
                if let idx = trips.firstIndex(where: { $0.id == saved.id }) {
                    trips[idx] = saved
                } else {
                    trips.append(saved)
                }
                Trip.saveAll(trips)
            } onDelete: { id in
                trips.removeAll { $0.id == id }
                Trip.saveAll(trips)
            }
        }
    }
}

// MARK: - Trip countdown display

private struct TripCountdownView: View {
    let trip: Trip
    let size: WidgetSize
    let onEdit: () -> Void

    private var daysRemaining: Int {
        let today = Calendar.current.startOfDay(for: .now)
        return max(0, Calendar.current.dateComponents([.day], from: today, to: trip.date).day ?? 0)
    }

    var body: some View {
        switch size {
        case .small:
            VStack(alignment: .leading, spacing: Tokens.tight) {
                Text("\(daysRemaining)")
                    .font(Tokens.Font.primaryValue(size: 48, weight: .ultraLight))
                    .foregroundStyle(Tokens.accent)
                    .contentTransition(.numericText())

                Text(trip.destination)
                    .font(Tokens.Font.bodyRowStrong)
                    .lineLimit(1)
                    .foregroundStyle(.primary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(daysRemaining) days until \(trip.destination)")

        case .medium, .large:
            VStack(alignment: .leading, spacing: Tokens.snug) {
                HStack(alignment: .firstTextBaseline, spacing: Tokens.tight) {
                    Text(trip.destination)
                        .font(Tokens.Font.bodyRowStrong)
                        .lineLimit(1)
                    Spacer(minLength: Tokens.snug)
                    Button {
                        onEdit()
                    } label: {
                        Image(systemName: "pencil")
                            .font(Tokens.Font.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Edit \(trip.destination)")
                    .help("Edit trip")
                }

                VStack(alignment: .leading, spacing: Tokens.snug) {
                    HStack(alignment: .firstTextBaseline, spacing: Tokens.sectionSpacing) {
                        Text("\(daysRemaining)")
                            .font(Tokens.Font.primaryValue(size: 54, weight: .ultraLight))
                            .foregroundStyle(Tokens.accent)
                            .contentTransition(.numericText())
                        Text(daysRemaining == 1 ? "day" : "days")
                            .font(Tokens.Font.bodyRow)
                            .foregroundStyle(.secondary)
                    }

                    Label {
                        Text(trip.date.formatted(.dateTime.month(.wide).day().year()))
                    } icon: {
                        Image(systemName: "calendar")
                            .foregroundStyle(Tokens.accent)
                    }
                    .font(Tokens.Font.caption)
                    .foregroundStyle(.tertiary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(daysRemaining) days until \(trip.destination)")
            }
        }
    }
}

// MARK: - Trip editor sheet

private struct TripEditor: View {
    @Environment(\.dismiss) private var dismiss

    @State private var destination: String
    @State private var date: Date
    private let tripID: UUID
    private let isEditing: Bool
    let onSave: (Trip) -> Void
    let onDelete: (UUID) -> Void

    init(trip: Trip?, onSave: @escaping (Trip) -> Void, onDelete: @escaping (UUID) -> Void) {
        let t = trip ?? Trip(destination: "", date: Calendar.current.date(byAdding: .month, value: 1, to: .now) ?? .now)
        _destination = State(initialValue: t.destination)
        _date = State(initialValue: t.date)
        tripID = t.id
        isEditing = trip != nil
        self.onSave = onSave
        self.onDelete = onDelete
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Destination", text: $destination)
                DatePicker("Date", selection: $date, displayedComponents: .date)

                if isEditing {
                    Button("Delete Trip", role: .destructive) {
                        onDelete(tripID)
                        dismiss()
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(isEditing ? "Edit Trip" : "New Trip")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trip = Trip(id: tripID, destination: destination, date: date)
                        onSave(trip)
                        dismiss()
                    }
                    .disabled(destination.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .frame(minWidth: Tokens.Size.editorMinWidth, minHeight: Tokens.Size.editorMinHeight)
    }
}

// MARK: - Trip model

struct Trip: Codable, Identifiable, Sendable {
    var id: UUID
    var destination: String
    var date: Date

    init(id: UUID = UUID(), destination: String, date: Date) {
        self.id = id
        self.destination = destination
        self.date = Calendar.current.startOfDay(for: date)
    }

    private static let key = "sky_trips"

    static func loadAll() -> [Trip] {
        if DemoMode.isEnabled { return [DemoFixtures.trip] }
        guard let data = UserDefaults.standard.data(forKey: key),
              let trips = try? JSONDecoder().decode([Trip].self, from: data) else {
            return defaultTrips
        }
        return trips
    }

    static func saveAll(_ trips: [Trip]) {
        guard !DemoMode.isEnabled else { return }
        if let data = try? JSONEncoder().encode(trips) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private static let defaultTrips: [Trip] = {
        var cal = Calendar.current
        let date = cal.date(from: DateComponents(year: 2026, month: 12, day: 20))!
        return [Trip(destination: "Thailand", date: date)]
    }()
}

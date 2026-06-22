import SwiftUI

// CANONICAL WIDGET PATTERN — agents replicate this shape:
//   AsyncCard handles loading/error/empty; the widget supplies fetch + content.

// Google Calendar colorId → accent color.
// https://developers.google.com/calendar/api/v3/reference/colors
private let calendarColorMap: [String: Color] = [
    "1": Color(red: 0.475, green: 0.525, blue: 0.796),  // Lavender
    "2": Color(red: 0.200, green: 0.714, blue: 0.475),  // Sage
    "3": Color(red: 0.557, green: 0.141, blue: 0.667),  // Grape
    "4": Color(red: 0.902, green: 0.486, blue: 0.451),  // Flamingo
    "5": Color(red: 0.965, green: 0.749, blue: 0.149),  // Banana
    "6": Color(red: 0.957, green: 0.318, blue: 0.118),  // Tangerine
    "7": Color(red: 0.012, green: 0.608, blue: 0.898),  // Peacock
    "8": Color(red: 0.380, green: 0.380, blue: 0.380),  // Graphite
    "9": Color(red: 0.247, green: 0.318, blue: 0.710),  // Blueberry
    "10": Color(red: 0.043, green: 0.502, blue: 0.263), // Basil
    "11": Color(red: 0.835, green: 0.000, blue: 0.000), // Tomato
]

private func eventAccent(_ colorId: String?) -> Color {
    guard let id = colorId, let c = calendarColorMap[id] else { return .secondary }
    return c
}

struct CalendarWidget: View {
    var body: some View {
        AsyncCard(
            title: "Calendar",
            symbol: "calendar.day.timeline.left",
            tint: Theme.accent,
            load: { try await APIClient.shared.get("/api/calendar") as [CalendarEvent] },
            isEmpty: \.isEmpty,
            emptyText: "No upcoming events"
        ) { events in
            let now = Date()
            let groups = groupByDay(events, now: now)
            VStack(alignment: .leading, spacing: Theme.contentSpacing) {
                ForEach(groups) { group in
                    DaySection(group: group, now: now)
                }
            }
        }
    }
}

// MARK: - Day grouping

private struct DayGroup: Identifiable {
    let id: String
    let label: String
    var events: [CalendarEvent]
}

private func startOfDay(_ date: Date) -> Date {
    Calendar.current.startOfDay(for: date)
}

private func dayLabel(_ date: Date, now: Date) -> String {
    let cal = Calendar.current
    if cal.isDateInToday(date) { return "Today" }
    if cal.isDateInTomorrow(date) { return "Tomorrow" }
    if cal.isDateInYesterday(date) { return "Yesterday" }
    let diff = cal.dateComponents([.day], from: startOfDay(now), to: startOfDay(date)).day ?? 0
    if diff > 1 && diff < 7 {
        return date.formatted(.dateTime.weekday(.wide))
    }
    return date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
}

private func groupByDay(_ events: [CalendarEvent], now: Date) -> [DayGroup] {
    var map: [String: DayGroup] = [:]
    var order: [String] = []
    for event in events {
        guard let date = ISO8601DateFormatter.parse(event.start) else { continue }
        let key = startOfDay(date).timeIntervalSince1970.description
        if map[key] == nil {
            map[key] = DayGroup(id: key, label: dayLabel(date, now: now), events: [])
            order.append(key)
        }
        map[key]?.events.append(event)
    }
    return order.compactMap { map[$0] }
}

// MARK: - Day section

private struct DaySection: View {
    let group: DayGroup
    let now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(group.label)
                .font(.caption2.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)

            VStack(spacing: 2) {
                ForEach(group.events) { event in
                    EventRow(event: event, now: now)
                }
            }
        }
    }
}

// MARK: - Event row

private struct EventRow: View {
    let event: CalendarEvent
    let now: Date

    var body: some View {
        let accent = eventAccent(event.colorId)
        let state = eventState
        let muted = state == .past

        let rowContent = HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .trailing, spacing: 2) {
                if event.allDay {
                    Text("all day")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.fill.tertiary, in: Capsule())
                } else if let date = ISO8601DateFormatter.parse(event.start) {
                    Text(date.formatted(date: .omitted, time: .shortened))
                        .font(.caption.weight(.semibold))
                        .monospacedDigit()
                    if let dur = durationText {
                        Text(dur)
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .frame(width: 50, alignment: .trailing)

            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                .fill(accent.opacity(muted ? 0.35 : 1.0))
                .frame(width: 3, height: 18)
                .padding(.top, 3)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(event.title)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                    if state == .now {
                        Text("Now")
                            .font(.system(size: 9, weight: .semibold))
                            .textCase(.uppercase)
                            .tracking(0.5)
                            .foregroundStyle(.green)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(.green.opacity(0.12), in: Capsule())
                    }
                }

                if let loc = event.location, !loc.isEmpty {
                    Label(loc, systemImage: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 4)

            if let rel = relativeLabel {
                Text(rel)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .padding(.top, 1)
            }
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .opacity(muted ? 0.55 : 1.0)

        if let urlString = event.url, let url = URL(string: urlString) {
            Link(destination: url) {
                rowContent
            }
            .buttonStyle(.plain)
        } else {
            rowContent
        }
    }

    // MARK: Computed helpers

    private enum EventState { case past, now, future }

    private var eventState: EventState {
        if event.allDay { return .future }
        guard let start = ISO8601DateFormatter.parse(event.start),
              let end = ISO8601DateFormatter.parse(event.end) else { return .future }
        if start <= now && end > now { return .now }
        if end <= now { return .past }
        return .future
    }

    private var relativeLabel: String? {
        if event.allDay { return "All day" }
        guard let start = ISO8601DateFormatter.parse(event.start),
              let end = ISO8601DateFormatter.parse(event.end) else { return nil }
        let diffMin = Int(start.timeIntervalSince(now) / 60)
        if diffMin < 0 {
            if end > now { return "Now" }
            return "Ended"
        }
        if diffMin < 60 { return "in \(diffMin)m" }
        if diffMin < 1440 {
            let h = diffMin / 60
            let m = diffMin % 60
            return m > 0 ? "in \(h)h \(m)m" : "in \(h)h"
        }
        return nil
    }

    private var durationText: String? {
        if event.allDay { return nil }
        guard let start = ISO8601DateFormatter.parse(event.start),
              let end = ISO8601DateFormatter.parse(event.end) else { return nil }
        let mins = Int(end.timeIntervalSince(start) / 60)
        guard mins > 0 else { return nil }
        if mins < 60 { return "\(mins)m" }
        let h = mins / 60
        let m = mins % 60
        return m > 0 ? "\(h)h \(m)m" : "\(h)h"
    }
}

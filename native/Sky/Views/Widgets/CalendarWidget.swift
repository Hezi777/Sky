import SwiftUI

// CANONICAL WIDGET PATTERN — agents replicate this shape:
//   AsyncCard handles loading/error/empty; the widget supplies fetch + content.

private func eventAccent(_ colorId: String?) -> Color {
    guard let id = colorId, let c = Tokens.calendarColors[id] else { return .secondary }
    return c
}

struct CalendarWidget: View {
    var body: some View {
        AsyncCard(
            title: "Calendar",
            symbol: "calendar.day.timeline.left",
            tint: Tokens.accent,
            load: { try await APIClient.shared.get("/api/calendar") as [CalendarEvent] },
            isEmpty: \.isEmpty,
            emptyText: "No upcoming events"
        ) { events in
            let now = Date()
            let groups = groupByDay(events, now: now)
            VStack(alignment: .leading, spacing: Tokens.contentSpacing) {
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
        VStack(alignment: .leading, spacing: Tokens.sectionSpacing) {
            Text(group.label)
                .font(.caption2.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)

            VStack(spacing: Tokens.extraTight) {
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

        let rowContent = HStack(alignment: .top, spacing: Tokens.snug) {
            VStack(alignment: .trailing, spacing: Tokens.extraTight) {
                if event.allDay {
                    Text("all day")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, Tokens.sectionSpacing)
                        .padding(.vertical, Tokens.extraTight)
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

            RoundedRectangle(cornerRadius: Tokens.tinyRadius, style: .continuous)
                .fill(accent.opacity(muted ? 0.35 : 1.0))
                .frame(width: 3, height: 18)
                .padding(.top, Tokens.badgePadding)

            VStack(alignment: .leading, spacing: Tokens.extraTight) {
                HStack(spacing: Tokens.sectionSpacing) {
                    Text(event.title)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                    if state == .now {
                        Text("Now")
                            .font(.system(size: 9, weight: .semibold))
                            .textCase(.uppercase)
                            .tracking(0.5)
                            .foregroundStyle(Tokens.positive)
                            .padding(.horizontal, Tokens.tight)
                            .padding(.vertical, Tokens.microSpacing)
                            .background(Tokens.positive.opacity(0.12), in: Capsule())
                    }
                }

                if let loc = event.location, !loc.isEmpty {
                    Label(loc, systemImage: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: Tokens.tight)

            if let rel = relativeLabel {
                Text(rel)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .padding(.top, Tokens.microSpacing)
            }
        }
        .padding(.vertical, Tokens.compact)
        .padding(.horizontal, Tokens.tight)
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

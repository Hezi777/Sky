import SwiftUI

// CANONICAL WIDGET PATTERN — agents replicate this shape:
//   AsyncCard handles loading/error/empty; the widget supplies fetch + content.

private func eventAccent(_ colorId: String?) -> Color {
    guard let id = colorId, let c = Tokens.calendarColors[id] else { return .secondary }
    return c
}

struct CalendarWidget: View {
    @Environment(DashboardStore.self) private var store
    @Environment(\.widgetSize) private var size

    var body: some View {
        AsyncCard(
            title: "Calendar",
            symbol: "calendar.day.timeline.left",
            tint: Tokens.accent,
            state: store.calendar,
            isEmpty: \.isEmpty,
            emptyText: "No upcoming events",
            reload: { await store.load(.calendar, force: true) }
        ) { events in
            CalendarContent(events: events, size: size)
        }
        .task { await store.load(.calendar) }
    }
}

// MARK: - Size-aware content

private struct CalendarContent: View {
    let events: [CalendarEvent]
    let size: WidgetSize

    var body: some View {
        let now = Date()
        switch size {
        case .small:
            CalendarCompact(events: events, now: now)
        case .medium:
            CalendarMedium(events: events, now: now)
        case .large:
            CalendarLarge(events: events, now: now)
        }
    }
}

// MARK: - Small: single focused next event or summary count

private struct CalendarCompact: View {
    let events: [CalendarEvent]
    let now: Date

    private var nextEvent: CalendarEvent? {
        events.first { event in
            guard let start = ISO8601DateFormatter.parse(event.start) else { return false }
            if event.allDay { return Calendar.current.isDateInToday(start) }
            return start > now
        }
    }

    private var todayCount: Int {
        events.filter { event in
            guard let start = ISO8601DateFormatter.parse(event.start) else { return false }
            return Calendar.current.isDateInToday(start)
        }.count
    }

    var body: some View {
        if let event = nextEvent {
            let accent = eventAccent(event.colorId)
            let isNow = eventIsNow(event, now: now)
            HStack(spacing: Tokens.snug) {
                RoundedRectangle(cornerRadius: Tokens.tinyRadius, style: .continuous)
                    .fill(accent)
                    .frame(width: Tokens.Size.eventBar, height: Tokens.Size.symbolBox)

                VStack(alignment: .leading, spacing: Tokens.tight) {
                    Text(event.title)
                        .font(Tokens.Font.bodyRowStrong)
                        .foregroundStyle(isNow ? Tokens.accent : .primary)
                        .lineLimit(2)

                    if event.allDay {
                        Text("All day")
                            .font(Tokens.Font.rowSubtitle)
                            .foregroundStyle(.secondary)
                    } else if let date = ISO8601DateFormatter.parse(event.start) {
                        Text(date.formatted(date: .omitted, time: .shortened))
                            .font(Tokens.Font.rowTrailingValue)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .accessibilityElement(children: .combine)
        } else {
            VStack(spacing: Tokens.tight) {
                Text("\(todayCount)")
                    .font(Tokens.Font.primaryValue(size: 34))
                    .foregroundStyle(.primary)
                Text("events today")
                    .font(Tokens.Font.rowSubtitle)
                    .foregroundStyle(.secondary)
            }
            .accessibilityLabel("\(todayCount) events today")
        }
    }
}

// MARK: - Medium: up to 2 day groups, 3 events each

private struct CalendarMedium: View {
    let events: [CalendarEvent]
    let now: Date

    var body: some View {
        let groups = groupByDay(events, now: now)
        VStack(alignment: .leading, spacing: Tokens.contentSpacing) {
            ForEach(groups.prefix(2)) { group in
                CalendarDaySection(group: group, now: now, maxEvents: 3, showLocation: false, showRelative: false)
            }
        }
    }
}

// MARK: - Large: all day groups, all events, location + relative time

private struct CalendarLarge: View {
    let events: [CalendarEvent]
    let now: Date

    var body: some View {
        let groups = groupByDay(events, now: now)
        VStack(alignment: .leading, spacing: Tokens.contentSpacing) {
            ForEach(groups) { group in
                CalendarDaySection(group: group, now: now, maxEvents: nil, showLocation: true, showRelative: true)
            }
        }
    }
}

// MARK: - Day section (shared)

private struct CalendarDaySection: View {
    let group: DayGroup
    let now: Date
    var maxEvents: Int?
    var showLocation: Bool
    var showRelative: Bool

    private var visibleEvents: [CalendarEvent] {
        if let max = maxEvents { return Array(group.events.prefix(max)) }
        return group.events
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionSpacing) {
            WidgetSectionHeader(title: group.label)

            VStack(spacing: Tokens.zeroSpacing) {
                ForEach(Array(visibleEvents.enumerated()), id: \.element.id) { index, event in
                    CalendarEventRow(
                        event: event,
                        now: now,
                        showLocation: showLocation,
                        showRelative: showRelative,
                        showsDivider: index < visibleEvents.count - 1
                    )
                }
            }
        }
    }
}

// MARK: - Event row using WidgetRow

private struct CalendarEventRow: View {
    let event: CalendarEvent
    let now: Date
    var showLocation: Bool
    var showRelative: Bool
    var showsDivider: Bool

    private var accent: Color { eventAccent(event.colorId) }
    private var isNow: Bool { eventIsNow(event, now: now) }
    private var isPast: Bool { eventIsPast(event, now: now) }

    private var subtitle: String? {
        guard showLocation, let loc = event.location, !loc.isEmpty else { return nil }
        return loc
    }

    var body: some View {
        let row = WidgetRow(
            title: event.title,
            subtitle: subtitle,
            showsDivider: showsDivider,
            leading: {
                RoundedRectangle(cornerRadius: Tokens.tinyRadius, style: .continuous)
                    .fill(accent.opacity(isPast ? 0.35 : 1.0))
                    .frame(width: Tokens.Size.eventBar, height: Tokens.Size.symbolBox)
            },
            trailing: { trailingContent }
        )
        .opacity(isPast ? 0.55 : 1.0)

        if let urlString = event.url, let url = URL(string: urlString) {
            Link(destination: url) { row }
                .buttonStyle(.plain)
        } else {
            row
        }
    }

    @ViewBuilder
    private var trailingContent: some View {
        if isNow {
            WidgetBadge(text: "Now", color: Tokens.accent)
        } else if event.allDay {
            WidgetBadge(text: "All day")
        } else if let date = ISO8601DateFormatter.parse(event.start) {
            VStack(alignment: .trailing, spacing: Tokens.extraTight) {
                Text(date.formatted(date: .omitted, time: .shortened))
                    .font(Tokens.Font.rowTrailingValue)
                    .foregroundStyle(.secondary)

                if showRelative, let rel = relativeLabel {
                    Text(rel)
                        .font(Tokens.Font.rowTrailingValue)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    private var relativeLabel: String? {
        if event.allDay { return nil }
        guard let start = ISO8601DateFormatter.parse(event.start),
              let end = ISO8601DateFormatter.parse(event.end) else { return nil }
        let diffMin = Int(start.timeIntervalSince(now) / 60)
        if diffMin < 0 {
            if end > now { return nil } // "Now" badge handles this
            return nil
        }
        if diffMin < 60 { return "in \(diffMin)m" }
        if diffMin < 1440 {
            let hours = diffMin / 60
            let mins = diffMin % 60
            return mins > 0 ? "in \(hours)h \(mins)m" : "in \(hours)h"
        }
        return nil
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

// MARK: - Event state helpers

private func eventIsNow(_ event: CalendarEvent, now: Date) -> Bool {
    if event.allDay { return false }
    guard let start = ISO8601DateFormatter.parse(event.start),
          let end = ISO8601DateFormatter.parse(event.end) else { return false }
    return start <= now && end > now
}

private func eventIsPast(_ event: CalendarEvent, now: Date) -> Bool {
    if event.allDay { return false }
    guard let end = ISO8601DateFormatter.parse(event.end) else { return false }
    return end <= now
}

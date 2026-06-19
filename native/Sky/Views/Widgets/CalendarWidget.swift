import SwiftUI

// CANONICAL WIDGET PATTERN — agents replicate this shape:
//   AsyncCard handles loading/error/empty; the widget supplies fetch + content.

struct CalendarWidget: View {
    var body: some View {
        AsyncCard(
            title: "Calendar",
            symbol: "calendar",
            tint: Theme.accent,
            load: { try await APIClient.shared.get("/api/calendar") as [CalendarEvent] },
            isEmpty: \.isEmpty,
            emptyText: "No upcoming events"
        ) { events in
            VStack(spacing: 10) {
                ForEach(events.prefix(5)) { EventRow(event: $0) }
            }
        }
    }
}

private struct EventRow: View {
    let event: CalendarEvent

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Theme.accent)
                .frame(width: 3, height: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                if let loc = event.location, !loc.isEmpty {
                    Label(loc, systemImage: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 8)
            Text(timeText)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }

    private var timeText: String {
        if event.allDay { return "All day" }
        guard let date = ISO8601DateFormatter.parse(event.start) else { return "" }
        return date.formatted(date: .omitted, time: .shortened)
    }
}

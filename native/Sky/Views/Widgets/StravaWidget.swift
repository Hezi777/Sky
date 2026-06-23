import SwiftUI

struct StravaWidget: View {
    @Environment(DashboardStore.self) private var store
    @Environment(\.widgetSize) private var size

    var body: some View {
        AsyncCard(
            title: "Strava",
            symbol: "figure.run",
            tint: Tokens.accent,
            state: store.strava,
            isEmpty: \.isEmpty,
            emptyText: "No recent activities",
            reload: { await store.load(.strava, force: true) }
        ) { activities in
            switch size {
            case .small:
                if let activity = activities.first {
                    CompactActivityRow(activity: activity)
                }

            default:
                VStack(spacing: Tokens.contentSpacing) {
                    ForEach(activities) { ActivityRow(activity: $0) }
                }
            }
        }
        .task { await store.load(.strava) }
    }
}

private struct CompactActivityRow: View {
    let activity: StravaActivity

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.snug) {
            HStack(spacing: Tokens.snug) {
                Image(systemName: symbol)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Tokens.accent)
                Text(activity.name)
                    .font(Tokens.Font.bodyRow)
                    .lineLimit(1)
            }

            Text(distanceText)
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }

    private var symbol: String {
        switch activity.type.lowercased() {
        case "run": return "figure.run"
        case "ride": return "figure.outdoor.cycle"
        case "swim": return "figure.pool.swim"
        case "walk", "hike": return "figure.walk"
        default: return "figure.mixed.cardio"
        }
    }

    private var distanceText: String {
        let km = activity.distance / 1000
        return String(format: "%.1f km", km)
    }
}

private struct ActivityRow: View {
    let activity: StravaActivity

    var body: some View {
        let content = HStack(spacing: Tokens.rowSpacing) {
            Image(systemName: symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Tokens.accent)
                .frame(width: Tokens.Size.activityIcon)

            VStack(alignment: .leading, spacing: Tokens.extraTight) {
                Text(activity.name)
                    .font(Tokens.Font.bodyRow)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(subtitleText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: Tokens.snug)

            VStack(alignment: .trailing, spacing: Tokens.extraTight) {
                Text(distanceText)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.primary)
                    .monospacedDigit()
                Text(durationText)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .monospacedDigit()
            }
        }

        if let stravaURL = URL(string: "https://www.strava.com/activities/\(activity.id)") {
            Link(destination: stravaURL) { content }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
        } else {
            content
                .accessibilityElement(children: .combine)
        }
    }

    private var symbol: String {
        switch activity.type.lowercased() {
        case "run": return "figure.run"
        case "ride": return "figure.outdoor.cycle"
        case "swim": return "figure.pool.swim"
        case "walk", "hike": return "figure.walk"
        default: return "figure.mixed.cardio"
        }
    }

    private var subtitleText: String {
        guard let date = ISO8601DateFormatter.parse(activity.startDate) else { return activity.type }
        return "\(activity.type) · \(date.formatted(date: .abbreviated, time: .omitted))"
    }

    private var distanceText: String {
        let km = activity.distance / 1000
        return String(format: "%.1f km", km)
    }

    private var durationText: String {
        let hours = activity.movingTime / 3600
        let minutes = (activity.movingTime % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

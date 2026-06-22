import SwiftUI

struct StravaWidget: View {
    @Environment(DashboardStore.self) private var store

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
            VStack(spacing: Tokens.contentSpacing) {
                ForEach(activities) { ActivityRow(activity: $0) }
            }
        }
        .task { await store.load(.strava) }
    }
}

private struct ActivityRow: View {
    let activity: StravaActivity

    private var stravaURL: URL {
        URL(string: "https://www.strava.com/activities/\(activity.id)")!
    }

    var body: some View {
        Link(destination: stravaURL) {
            HStack(spacing: Tokens.rowSpacing) {
                Image(systemName: symbol)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Tokens.accent)
                    .frame(width: Tokens.Size.activityIcon)

                VStack(alignment: .leading, spacing: Tokens.extraTight) {
                    Text(activity.name)
                        .font(.subheadline.weight(.medium))
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
        }
        .buttonStyle(.plain)
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
        activity.type
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

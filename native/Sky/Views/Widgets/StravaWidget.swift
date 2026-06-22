import SwiftUI

struct StravaWidget: View {
    // Decodes either the happy-path array or the {error} not-connected shape,
    // since the backend returns the error with HTTP 200 (calm placeholder, not
    // a scary error state).
    private enum Payload: Decodable, Sendable {
        case activities([StravaActivity])
        case notConnected(String)

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let activities = try? container.decode([StravaActivity].self) {
                self = .activities(activities)
            } else {
                let body = try container.decode(APIErrorBody.self)
                self = .notConnected(body.error)
            }
        }
    }

    var body: some View {
        AsyncCard(
            title: "Strava",
            symbol: "figure.run",
            tint: Theme.accent,
            load: { try await APIClient.shared.get("/api/strava") as Payload },
            isEmpty: { payload in
                if case .activities(let a) = payload { return a.isEmpty }
                return false
            },
            emptyText: "No recent activities"
        ) { payload in
            switch payload {
            case .notConnected:
                Text("Connect Strava in settings")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, minHeight: 44)
            case .activities(let activities):
                VStack(spacing: Theme.contentSpacing) {
                    ForEach(activities) { ActivityRow(activity: $0) }
                }
            }
        }
    }
}

private struct ActivityRow: View {
    let activity: StravaActivity

    private var stravaURL: URL {
        URL(string: "https://www.strava.com/activities/\(activity.id)")!
    }

    var body: some View {
        Link(destination: stravaURL) {
            HStack(spacing: 10) {
                Image(systemName: symbol)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 2) {
                    Text(activity.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text(subtitleText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 2) {
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

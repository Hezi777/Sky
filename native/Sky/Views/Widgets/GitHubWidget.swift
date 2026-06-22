import SwiftUI

struct GitHubWidget: View {
    @State private var data: GithubResponse?
    @State private var errorMessage: String?

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: Theme.contentSpacing) {
                CardHeader(title: "GitHub Activity", symbol: "curlybraces", tint: Theme.accent) {
                    if let data {
                        Text("\(data.totalContributions.formatted(.number.grouping(.automatic))) contributions")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                if let errorMessage {
                    WidgetError(message: errorMessage) { Task { await reload() } }
                } else if let data {
                    if data.repos.isEmpty && data.contributions.isEmpty {
                        EmptyHint(text: "No activity")
                    } else {
                        ContributionHeatmap(days: data.contributions)

                        if !data.repos.isEmpty {
                            VStack(spacing: 8) {
                                ForEach(data.repos.prefix(3)) { RepoRow(repo: $0) }
                            }
                        }
                    }
                } else {
                    WidgetLoading()
                }
            }
        }
        .task { await reload() }
    }

    private func reload() async {
        errorMessage = nil
        do {
            data = try await APIClient.shared.get("/api/github") as GithubResponse
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
    }
}

// MARK: - Heatmap (replicates git-hub-calendar.tsx)

private struct ContributionHeatmap: View {
    let days: [GithubContributionDay]

    private let gap: CGFloat = 3
    private let labelWidth: CGFloat = 26

    private static let dayLabels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 1 // Sunday
        return cal
    }

    /// 53 columns of 7 days, starting from startOfWeek(today - 364).
    private var weeks: [[Date]] {
        let cal = calendar
        let today = cal.startOfDay(for: Date())
        guard
            let minus364 = cal.date(byAdding: .day, value: -364, to: today),
            let startWeek = cal.dateInterval(of: .weekOfYear, for: minus364)?.start
        else { return [] }

        var result: [[Date]] = []
        var weekStart = startWeek
        while weekStart <= today {
            var week: [Date] = []
            for d in 0..<7 {
                if let day = cal.date(byAdding: .day, value: d, to: weekStart) {
                    week.append(day)
                }
            }
            result.append(week)
            guard let next = cal.date(byAdding: .day, value: 7, to: weekStart) else { break }
            weekStart = next
        }
        return result
    }

    private var contributionsByDate: [String: Int] {
        Dictionary(days.map { ($0.date, $0.count) }, uniquingKeysWith: { a, _ in a })
    }

    private static let keyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "MMM"
        return f
    }()

    /// Month label per column where a new month begins.
    private var monthLabels: [Int: String] {
        let cal = calendar
        var labels: [Int: String] = [:]
        var seenMonth = ""
        for (index, week) in weeks.enumerated() {
            let firstOfMonth = week.first { cal.component(.day, from: $0) == 1 }
            guard let labelDate = firstOfMonth ?? (index == 0 ? week.first : nil) else { continue }
            let key = "\(cal.component(.year, from: labelDate))-\(cal.component(.month, from: labelDate))"
            if key == seenMonth { continue }
            seenMonth = key
            labels[index] = Self.monthFormatter.string(from: labelDate)
        }
        return labels
    }

    @State private var availableWidth: CGFloat = 0

    private var cell: CGFloat {
        let cols = weeks
        guard !cols.isEmpty, availableWidth > 0 else { return 11 }
        return max(2, (availableWidth - labelWidth - CGFloat(cols.count - 1) * gap) / CGFloat(cols.count))
    }

    var body: some View {
        let cols = weeks
        let cell = self.cell
        VStack(alignment: .leading, spacing: 6) {
            // Month row
            HStack(alignment: .top, spacing: gap) {
                Color.clear.frame(width: labelWidth, height: 12)
                ForEach(cols.indices, id: \.self) { i in
                    ZStack(alignment: .leading) {
                        Color.clear.frame(width: cell, height: 12)
                        if let label = monthLabels[i] {
                            Text(label)
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                                .fixedSize()
                        }
                    }
                }
            }

            // Weekday labels + grid
            HStack(alignment: .top, spacing: gap) {
                VStack(alignment: .leading, spacing: gap) {
                    ForEach(Self.dayLabels, id: \.self) { d in
                        Text(d)
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                            .frame(width: labelWidth, height: cell, alignment: .leading)
                    }
                }

                ForEach(cols.indices, id: \.self) { c in
                    VStack(spacing: gap) {
                        ForEach(cols[c], id: \.self) { day in
                            let key = Self.keyFormatter.string(from: day)
                            let count = contributionsByDate[key] ?? 0
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(color(for: count))
                                .frame(width: cell, height: cell)
                        }
                    }
                }
            }

            // Legend
            HStack(spacing: 4) {
                Text("Less")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                ForEach(Theme.githubLevels.indices, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(Theme.githubLevels[i])
                        .frame(width: 11, height: 11)
                }
                Text("More")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 4)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .background(
            GeometryReader { geo in
                Color.clear.preference(key: HeatmapWidthKey.self, value: geo.size.width)
            }
        )
        .onPreferenceChange(HeatmapWidthKey.self) { availableWidth = $0 }
    }

    // Matches web getColor(): count thresholds, not level.
    private func color(for count: Int) -> Color {
        switch count {
        case 0: return Theme.githubLevels[0]
        case 1: return Theme.githubLevels[1]
        case 2: return Theme.githubLevels[2]
        case 3: return Theme.githubLevels[3]
        default: return Theme.githubLevels[4]
        }
    }
}

// MARK: - Repo row

private struct RepoRow: View {
    let repo: GithubRepo

    var body: some View {
        Link(destination: URL(string: repo.url) ?? URL(string: "https://github.com")!) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(repo.name)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer(minLength: 8)
                    Label("\(repo.stars)", systemImage: "star")
                        .labelStyle(.titleAndIcon)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(secondLine)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: Theme.innerRadius, style: .continuous)
                    .fill(.quaternary.opacity(0.4))
            )
            .contentShape(RoundedRectangle(cornerRadius: Theme.innerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var secondLine: String {
        "\(repo.language ?? "Code") · pushed \(relativeTime(repo.pushedAt))"
    }

    private func relativeTime(_ iso: String) -> String {
        guard let date = ISO8601DateFormatter.parse(iso) else { return "recently" }
        let sec = Int(Date().timeIntervalSince(date))
        if sec < 60 { return "just now" }
        let min = sec / 60
        if min < 60 { return "\(min)m ago" }
        let hr = min / 60
        if hr < 24 { return "\(hr)h ago" }
        let day = hr / 24
        if day < 30 { return "\(day)d ago" }
        let mo = day / 30
        if mo < 12 { return "\(mo)mo ago" }
        return "\(mo / 12)y ago"
    }
}

// MARK: - Preference key for heatmap width measurement

private struct HeatmapWidthKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

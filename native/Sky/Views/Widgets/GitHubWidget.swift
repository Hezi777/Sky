import SwiftUI

struct GitHubWidget: View {
    @Environment(DashboardStore.self) private var store

    var body: some View {
        WidgetShell(
            title: "GitHub Activity",
            symbol: "curlybraces",
            tint: Tokens.accent,
            accessory: {
                if case .loaded(let data) = store.github {
                    Text("\(data.totalContributions.formatted(.number.grouping(.automatic))) contributions")
                        .font(Tokens.Font.caption)
                        .foregroundStyle(.secondary)
                }
            }
        ) {
            switch store.github {
            case .failed(let message):
                WidgetError(message: message) { Task { await store.load(.github, force: true) } }
            case .loaded(let data):
                if data.repos.isEmpty && data.contributions.isEmpty {
                    EmptyHint(text: "No activity")
                } else {
                    ContributionHeatmap(days: data.contributions)

                    if !data.repos.isEmpty {
                        VStack(spacing: Tokens.snug) {
                            ForEach(data.repos.prefix(3)) { RepoRow(repo: $0) }
                        }
                    }
                }
            case .idle, .loading:
                WidgetLoading()
            }
        }
        .task { await store.load(.github) }
    }
}

// MARK: - Heatmap (replicates git-hub-calendar.tsx)

private struct ContributionHeatmap: View {
    let days: [GithubContributionDay]

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

    private var gap: CGFloat {
        availableWidth < 500 ? Tokens.microSpacing : Tokens.badgePadding
    }

    private var labelWidth: CGFloat {
        availableWidth < 500 ? 0 : 26
    }

    private var cell: CGFloat {
        let cols = weeks
        guard !cols.isEmpty, availableWidth > 0 else { return 11 }
        let availableForCells = availableWidth - labelWidth - CGFloat(cols.count) * gap
        return min(
            Tokens.Size.heatmapCell,
            max(2, availableForCells / CGFloat(cols.count))
        )
    }

    var body: some View {
        let cols = weeks
        let cell = self.cell
        VStack(alignment: .leading, spacing: Tokens.sectionSpacing) {
            // Month row
            HStack(alignment: .top, spacing: gap) {
                Color.clear.frame(width: labelWidth, height: Tokens.Size.compactControl)
                ForEach(cols.indices, id: \.self) { i in
                    ZStack(alignment: .leading) {
                        Color.clear.frame(width: cell, height: Tokens.Size.compactControl)
                        if let label = monthLabels[i] {
                            Text(label)
                                .font(Tokens.Font.microLabel)
                                .foregroundStyle(.secondary)
                                .fixedSize()
                        }
                    }
                }
            }

            // Weekday labels + grid
            HStack(alignment: .top, spacing: gap) {
                if labelWidth > 0 {
                    VStack(alignment: .leading, spacing: gap) {
                        ForEach(Self.dayLabels, id: \.self) { day in
                            Text(day)
                                .font(Tokens.Font.microLabel)
                                .foregroundStyle(.secondary)
                                .frame(width: labelWidth, height: cell, alignment: .leading)
                        }
                    }
                }

                ForEach(cols.indices, id: \.self) { c in
                    VStack(spacing: gap) {
                        ForEach(cols[c], id: \.self) { day in
                            let key = Self.keyFormatter.string(from: day)
                            let count = contributionsByDate[key] ?? 0
                            RoundedRectangle(cornerRadius: Tokens.barRadius, style: .continuous)
                                .fill(color(for: count))
                                .frame(width: cell, height: cell)
                        }
                    }
                }
            }

            // Legend
            HStack(spacing: Tokens.tight) {
                Text("Less")
                    .font(Tokens.Font.microLabel)
                    .foregroundStyle(.secondary)
                ForEach(Tokens.githubLevels.indices, id: \.self) { i in
                    RoundedRectangle(cornerRadius: Tokens.barRadius, style: .continuous)
                        .fill(Tokens.githubLevels[i])
                        .frame(width: Tokens.Size.heatmapCell, height: Tokens.Size.heatmapCell)
                }
                Text("More")
                    .font(Tokens.Font.microLabel)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, Tokens.tight)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .background(
            GeometryReader { geo in
                Color.clear.preference(key: HeatmapWidthKey.self, value: geo.size.width)
            }
        )
        .onPreferenceChange(HeatmapWidthKey.self) { availableWidth = $0 }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Contribution history")
        .accessibilityValue("\(days.reduce(0) { $0 + $1.count }) contributions in the past year")
    }

    // Matches web getColor(): count thresholds, not level.
    private func color(for count: Int) -> Color {
        switch count {
        case 0: return Tokens.githubLevels[0]
        case 1: return Tokens.githubLevels[1]
        case 2: return Tokens.githubLevels[2]
        case 3: return Tokens.githubLevels[3]
        default: return Tokens.githubLevels[4]
        }
    }
}

// MARK: - Repo row

private struct RepoRow: View {
    let repo: GithubRepo

    var body: some View {
        Link(destination: URL(string: repo.url) ?? URL(string: "https://github.com")!) {
            VStack(alignment: .leading, spacing: Tokens.extraTight) {
                HStack(spacing: Tokens.snug) {
                    Text(repo.name)
                        .font(Tokens.Font.bodyRow)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer(minLength: Tokens.snug)
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
            .padding(.horizontal, Tokens.contentSpacing)
            .padding(.vertical, Tokens.snug)
            .background(
                RoundedRectangle(cornerRadius: Tokens.innerRadius, style: .continuous)
                    .fill(.quaternary.opacity(0.4))
            )
            .contentShape(RoundedRectangle(cornerRadius: Tokens.innerRadius, style: .continuous))
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

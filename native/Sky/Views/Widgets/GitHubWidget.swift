import SwiftUI

struct GitHubWidget: View {
    var body: some View {
        AsyncCard(
            title: "GitHub",
            symbol: "chevron.left.forwardslash.chevron.right",
            tint: Theme.accent,
            load: { try await APIClient.shared.get("/api/github") as GithubResponse },
            isEmpty: { $0.repos.isEmpty && $0.contributions.isEmpty },
            emptyText: "No activity"
        ) { data in
            VStack(alignment: .leading, spacing: 16) {
                ContributionTotal(total: data.totalContributions)
                ContributionHeatmap(days: data.contributions)
                if !data.repos.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(data.repos.prefix(3)) { RepoRow(repo: $0) }
                    }
                }
            }
        }
    }
}

// MARK: - Total contributions

private struct ContributionTotal: View {
    let total: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(total)")
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(total)))
                .animation(.snappy, value: total)
            Text("contributions this year")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Heatmap

private struct ContributionHeatmap: View {
    let days: [GithubContributionDay]

    // Last ~16 weeks (112 days), oldest first, grouped into columns of 7.
    private var weeks: [[GithubContributionDay]] {
        let recent = Array(days.suffix(16 * 7))
        return stride(from: 0, to: recent.count, by: 7).map {
            Array(recent[$0 ..< min($0 + 7, recent.count)])
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 3) {
            ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                VStack(spacing: 3) {
                    ForEach(week) { day in
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(color(for: day.level))
                            .frame(width: 11, height: 11)
                    }
                }
            }
        }
    }

    private func color(for level: Int) -> Color {
        switch level {
        case 1: return .green.opacity(0.35)
        case 2: return .green.opacity(0.55)
        case 3: return .green.opacity(0.78)
        case 4: return .green
        default: return .secondary.opacity(0.15)
        }
    }
}

// MARK: - Repo row

private struct RepoRow: View {
    let repo: GithubRepo

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(languageColor)
                .frame(width: 8, height: 8)
            Text(repo.name)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
            Spacer(minLength: 8)
            Label("\(repo.stars)", systemImage: "star.fill")
                .labelStyle(.titleAndIcon)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }

    private var languageColor: Color {
        guard let lang = repo.language else { return .secondary.opacity(0.4) }
        switch lang {
        case "Swift": return .orange
        case "TypeScript", "JavaScript": return .yellow
        case "Python": return .blue
        case "Go": return .cyan
        case "Rust": return .red
        default: return Theme.accent
        }
    }
}

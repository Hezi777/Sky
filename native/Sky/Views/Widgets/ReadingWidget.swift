import SwiftUI

struct ReadingWidget: View {
    @Environment(DashboardStore.self) private var store

    var body: some View {
        AsyncCard(
            title: "Reading",
            symbol: "book",
            tint: Tokens.accent,
            state: store.reading,
            isEmpty: \.isEmpty,
            emptyText: "Not reading anything",
            reload: { await store.load(.reading, force: true) }
        ) { books in
            VStack(spacing: Tokens.contentSpacing) {
                ForEach(books) { BookRow(book: $0) }
            }
        }
        .task { await store.load(.reading) }
    }
}

private struct BookRow: View {
    let book: ReadingBook

    var body: some View {
        let content = HStack(alignment: .top, spacing: Tokens.contentSpacing) {
            AsyncImage(url: book.cover.flatMap(URL.init)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    ZStack {
                        RoundedRectangle(cornerRadius: Tokens.smallRadius, style: .continuous)
                            .fill(.quaternary)
                        Image(systemName: "book.closed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(width: Tokens.Size.bookCoverWidth, height: Tokens.Size.bookCoverHeight)
            .clipShape(RoundedRectangle(cornerRadius: Tokens.smallRadius, style: .continuous))
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Tokens.tight) {
                Text(book.title)
                    .font(Tokens.Font.bodyRow)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                if let author = book.author, !author.isEmpty {
                    Text(author)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                ProgressBar(progress: book.progress)
                    .padding(.top, Tokens.extraTight)

                HStack(spacing: Tokens.tight) {
                    Text(pageText)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .monospacedDigit()
                    Spacer(minLength: Tokens.tight)
                    Text("\(book.progress)%")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(Tokens.accent)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
            }
        }

        if let linkURL = URL(string: book.url) {
            Link(destination: linkURL) { content }
                .buttonStyle(.plain)
        } else {
            content
        }
    }

    private var pageText: String {
        let current = book.currentPage.map(String.init) ?? "—"
        let total = book.totalPages.map(String.init) ?? "—"
        return "p. \(current) / \(total)"
    }
}

private struct ProgressBar: View {
    let progress: Int // 0...100

    var body: some View {
        GeometryReader { geo in
            let fraction = max(0, min(1, Double(progress) / 100))
            ZStack(alignment: .leading) {
                Capsule().fill(.quaternary)
                Capsule()
                    .fill(Tokens.accent)
                    .frame(width: geo.size.width * fraction)
            }
        }
        .frame(height: Tokens.Size.progressBar)
        .accessibilityLabel("Reading progress")
        .accessibilityValue((Double(progress) / 100).formatted(.percent))
    }
}

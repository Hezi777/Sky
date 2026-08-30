import SwiftUI

struct ReadingWidget: View {
    @Environment(DashboardStore.self) private var store
    @Environment(\.widgetSize) private var size

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
            switch size {
            case .small:
                if let book = books.first {
                    CompactBookView(book: book)
                }

            default:
                VStack(spacing: Tokens.zeroSpacing) {
                    ForEach(Array(books.enumerated()), id: \.element.id) { index, book in
                        BookRowView(book: book, showsDivider: index < books.count - 1)
                    }
                }
            }
        }
        .task { await store.load(.reading) }
    }
}

// MARK: - Small: compact single book

private struct CompactBookView: View {
    let book: ReadingBook

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.snug) {
            Text(book.title)
                .font(Tokens.Font.bodyRow)
                .foregroundStyle(.primary)
                .lineLimit(2)

            WidgetProgressBar(progress: Double(book.progress) / 100, tint: Tokens.accent)

            Text(
                (Double(book.progress) / 100).formatted(
                    .percent.precision(.fractionLength(0))
                )
            )
            .font(Tokens.Font.rowTrailingValue)
            .foregroundStyle(Tokens.accent)
            .contentTransition(.numericText())
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(book.title), \(book.progress) percent")
    }
}

// MARK: - Medium: full book row with cover

private struct BookRowView: View {
    let book: ReadingBook
    var showsDivider: Bool = true

    var body: some View {
        let row = VStack(spacing: Tokens.zeroSpacing) {
            WidgetRow(
                title: book.title,
                subtitle: book.author,
                showsDivider: false,
                leading: {
                    AsyncImage(url: book.cover.flatMap(URL.init)) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        default:
                            ZStack {
                                RoundedRectangle(cornerRadius: Tokens.mediaRadius, style: .continuous)
                                    .fill(.quaternary)
                                Image(systemName: "book.closed")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(width: Tokens.Size.bookCoverWidth, height: Tokens.Size.bookCoverHeight)
                    .clipShape(RoundedRectangle(cornerRadius: Tokens.mediaRadius, style: .continuous))
                    .accessibilityHidden(true)
                },
                trailing: {
                    VStack(alignment: .trailing, spacing: Tokens.extraTight) {
                        Text(pageText)
                            .font(Tokens.Font.rowTrailingValue)
                            .foregroundStyle(.tertiary)
                        Text(
                            (Double(book.progress) / 100).formatted(
                                .percent.precision(.fractionLength(0))
                            )
                        )
                        .font(Tokens.Font.rowTrailingValue)
                        .foregroundStyle(Tokens.accent)
                        .contentTransition(.numericText())
                    }
                }
            )

            WidgetProgressBar(progress: Double(book.progress) / 100, tint: Tokens.accent)
                .padding(.leading, Tokens.Size.bookCoverWidth + Tokens.rowSpacing)

            if showsDivider {
                Divider()
                    .padding(.leading, Tokens.Size.bookCoverWidth + Tokens.rowSpacing)
                    .padding(.top, Tokens.snug)
            }
        }

        if let linkURL = URL(string: book.url) {
            Link(destination: linkURL) { row }
                .buttonStyle(.plain)
        } else {
            row
        }
    }

    private var pageText: String {
        let current = book.currentPage.map(String.init) ?? "—"
        let total = book.totalPages.map(String.init) ?? "—"
        return "p. \(current)/\(total)"
    }
}

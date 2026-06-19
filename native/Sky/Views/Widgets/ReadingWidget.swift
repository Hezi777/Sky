import SwiftUI

struct ReadingWidget: View {
    var body: some View {
        AsyncCard(
            title: "Reading",
            symbol: "book",
            tint: Theme.accent,
            load: { try await APIClient.shared.get("/api/notion/reading") as [ReadingBook] },
            isEmpty: \.isEmpty,
            emptyText: "Not reading anything"
        ) { books in
            VStack(spacing: 12) {
                ForEach(books) { BookRow(book: $0) }
            }
        }
    }
}

private struct BookRow: View {
    let book: ReadingBook

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let cover = book.cover, let url = URL(string: cover) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        Rectangle().fill(.quaternary)
                    }
                }
                .frame(width: 36, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                if let author = book.author, !author.isEmpty {
                    Text(author)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                ProgressBar(progress: book.progress)
                    .padding(.top, 2)
                Text(pageText)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .monospacedDigit()
            }
        }
    }

    private var pageText: String {
        let current = book.currentPage.map(String.init) ?? "—"
        let total = book.totalPages.map(String.init) ?? "—"
        return "p.\(current)/\(total)"
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
                    .fill(Theme.accent)
                    .frame(width: geo.size.width * fraction)
            }
        }
        .frame(height: 4)
    }
}

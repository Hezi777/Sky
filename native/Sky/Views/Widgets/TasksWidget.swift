import SwiftUI

private struct EmptyResponse: Decodable {}

struct TasksWidget: View {
    @State private var tasks: [TickTickTask]?
    @State private var errorMessage: String?

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                CardHeader(title: "Tasks", symbol: "checklist", tint: Theme.accent)

                if let errorMessage {
                    WidgetError(message: errorMessage) { Task { await reload() } }
                } else if let tasks {
                    if tasks.isEmpty {
                        EmptyHint(text: "All clear today")
                    } else {
                        VStack(spacing: 8) {
                            ForEach(tasks.prefix(6)) { task in
                                TaskRow(task: task) { complete(task) }
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
            tasks = try await APIClient.shared.get("/api/ticktick") as [TickTickTask]
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func complete(_ task: TickTickTask) {
        withAnimation {
            tasks?.removeAll { $0.id == task.id }
        }
        Task {
            do {
                _ = try await APIClient.shared.post("/api/ticktick/complete", body: ["id": task.id]) as EmptyResponse
            } catch {
                // Re-insert on failure
                withAnimation {
                    tasks?.append(task)
                }
            }
        }
    }
}

private struct TaskRow: View {
    let task: TickTickTask
    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onComplete) {
                Circle()
                    .strokeBorder(priorityColor, lineWidth: 1.5)
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)

                if !task.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(task.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.fill.tertiary, in: Capsule())
                        }
                    }
                }
            }

            Spacer(minLength: 8)

            if let dueDate = task.dueDate, let date = ISO8601DateFormatter.parse(dueDate) {
                Text(date.formatted(date: .omitted, time: .shortened))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var priorityColor: Color {
        switch task.priority {
        case .none: return .secondary
        case .low: return .blue
        case .medium: return .yellow
        case .high: return .red
        }
    }
}

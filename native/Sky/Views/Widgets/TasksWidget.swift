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
                        VStack(spacing: 0) {
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

// MARK: - Task row

private struct TaskRow: View {
    let task: TickTickTask
    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            // Priority circle (tap to complete)
            Button(action: onComplete) {
                Circle()
                    .strokeBorder(priorityColor, lineWidth: 1.5)
                    .frame(width: 18, height: 18)
            }
            .buttonStyle(.plain)

            // Title
            Text(task.title)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Metadata: subtasks, tags, due time
            TaskMetadata(task: task)
        }
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    private var priorityColor: Color {
        switch task.priority {
        case .none: return .gray
        case .low: return .blue
        case .medium: return .yellow
        case .high: return .red
        }
    }
}

// MARK: - Task metadata (subtasks, tags, due time)

private struct TaskMetadata: View {
    let task: TickTickTask

    var body: some View {
        let hasContent = task.subtaskCount > 0 || !task.tags.isEmpty || task.dueDate != nil
        if hasContent {
            HStack(spacing: 8) {
                if task.subtaskCount > 0 {
                    Label {
                        Text("\(task.subtaskCount)")
                            .monospacedDigit()
                    } icon: {
                        Image(systemName: "list.bullet")
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }

                ForEach(task.tags.prefix(2), id: \.self) { tag in
                    Text(tag)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.fill.tertiary, in: Capsule())
                        .lineLimit(1)
                }

                if let dueDate = task.dueDate, let date = ISO8601DateFormatter.parse(dueDate) {
                    Label {
                        Text(date.formatted(date: .omitted, time: .shortened))
                            .monospacedDigit()
                    } icon: {
                        Image(systemName: "clock")
                    }
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(Theme.accent.opacity(0.8))
                }
            }
        }
    }
}

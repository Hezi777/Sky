import SwiftUI

struct TasksWidget: View {
    @Environment(DashboardStore.self) private var store
    @State private var completed: Set<String> = []

    // Keep completed tasks in the list (so the total is stable) but filter them
    // from view — mirrors the web ticktick widget's progress ring.
    private var visible: [TickTickTask] {
        guard case .loaded(let tasks) = store.tasks else { return [] }
        return tasks.filter { !completed.contains($0.id) }
    }

    var body: some View {
        WidgetShell(title: "Tasks", symbol: "checklist", tint: Tokens.accent) {
            if case .loaded(let tasks) = store.tasks, !tasks.isEmpty {
                TaskProgressRing(completed: completed.count, total: tasks.count)
            }
        } content: {
            switch store.tasks {
            case .failed(let message):
                WidgetError(message: message) { Task { await store.load(.tasks, force: true) } }
            case .loaded(let tasks):
                if tasks.isEmpty {
                    EmptyHint(text: "All clear today")
                } else if visible.isEmpty {
                    EmptyHint(text: "All done — nice work")
                } else {
                    VStack(spacing: Tokens.zeroSpacing) {
                        ForEach(visible.prefix(6)) { task in
                            TaskRow(task: task) { complete(task) }
                        }
                    }
                }
            case .idle, .loading:
                WidgetLoading()
            }
        }
        .task { await store.load(.tasks) }
    }

    private func complete(_ task: TickTickTask) {
        withAnimation { _ = completed.insert(task.id) }
        Task {
            if !(await store.completeTask(task)) {
                withAnimation { _ = completed.remove(task.id) }
            }
        }
    }
}

// MARK: - Progress ring

private struct TaskProgressRing: View {
    let completed: Int
    let total: Int

    var body: some View {
        let fraction = total > 0 ? Double(completed) / Double(total) : 0

        ZStack {
            // Background track
            Circle()
                .strokeBorder(Color.secondary.opacity(0.12), lineWidth: 4)

            // Progress arc
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(Tokens.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.4), value: fraction)

            Text("\(completed)/\(total)")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .frame(width: Tokens.Size.progressRing, height: Tokens.Size.progressRing)
    }
}

// MARK: - Task row

private struct TaskRow: View {
    let task: TickTickTask
    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: Tokens.rowSpacing) {
            // Priority circle (tap to complete)
            Button(action: onComplete) {
                Circle()
                    .strokeBorder(priorityColor, lineWidth: 1.5)
                    .frame(width: Tokens.Size.symbolBox, height: Tokens.Size.symbolBox)
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
        .padding(.vertical, Tokens.snug)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    private var priorityColor: Color {
        switch task.priority {
        case .none: return Tokens.neutral
        case .low: return Tokens.info
        case .medium: return Tokens.caution
        case .high: return Tokens.negative
        }
    }
}

// MARK: - Task metadata (subtasks, tags, due time)

private struct TaskMetadata: View {
    let task: TickTickTask

    var body: some View {
        let hasContent = task.subtaskCount > 0 || !task.tags.isEmpty || task.dueDate != nil
        if hasContent {
            HStack(spacing: Tokens.snug) {
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
                        .padding(.horizontal, Tokens.sectionSpacing)
                        .padding(.vertical, Tokens.extraTight)
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
                    .foregroundStyle(Tokens.accent.opacity(0.8))
                }
            }
        }
    }
}

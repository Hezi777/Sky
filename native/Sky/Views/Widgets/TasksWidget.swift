import SwiftUI

struct TasksWidget: View {
    @Environment(DashboardStore.self) private var store
    @Environment(\.widgetSize) private var size
    @State private var completed: Set<String> = []

    // Keep completed tasks in the list (so the total is stable) but filter them
    // from view — mirrors the web ticktick widget's progress ring.
    private var visible: [TickTickTask] {
        guard case .loaded(let tasks) = store.tasks else { return [] }
        return tasks.filter { !completed.contains($0.id) }
    }

    /// Max visible tasks based on widget size.
    private var maxVisibleTasks: Int {
        switch size {
        case .small: 0
        case .medium: 4
        case .large: 10
        }
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
                } else if size == .small {
                    smallContent(tasks: tasks)
                } else if visible.isEmpty {
                    EmptyHint(text: "All done — nice work")
                } else {
                    taskList
                }
            case .idle, .loading:
                WidgetLoading()
            }
        }
        .task { await store.load(.tasks) }
    }

    // MARK: - Small: centered progress ring with "N left" label

    @ViewBuilder
    private func smallContent(tasks: [TickTickTask]) -> some View {
        let remaining = tasks.count - completed.count
        VStack(spacing: Tokens.snug) {
            TaskProgressRing(completed: completed.count, total: tasks.count)

            Text("\(remaining) left")
                .font(Tokens.Font.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    // MARK: - Medium / Large: task rows

    @ViewBuilder
    private var taskList: some View {
        let limit = maxVisibleTasks
        VStack(spacing: Tokens.zeroSpacing) {
            ForEach(Array(visible.prefix(limit).enumerated()), id: \.element.id) { index, task in
                let isLast = index >= min(visible.count, limit) - 1
                taskRow(task: task, showsDivider: !isLast)
            }
        }
    }

    @ViewBuilder
    private func taskRow(task: TickTickTask, showsDivider: Bool) -> some View {
        WidgetRow(
            title: task.title,
            subtitle: taskSubtitle(task),
            showsDivider: showsDivider,
            leading: {
                Button { complete(task) } label: {
                    Circle()
                        .strokeBorder(priorityColor(task.priority), lineWidth: Tokens.Chart.lineWidth)
                        .frame(
                            width: Tokens.Size.symbolBox,
                            height: Tokens.Size.symbolBox
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Complete \(task.title)")
                .help("Mark task complete")
            },
            trailing: {
                taskTrailing(task)
            }
        )
    }

    @ViewBuilder
    private func taskTrailing(_ task: TickTickTask) -> some View {
        if let dueDate = task.dueDate, let date = ISO8601DateFormatter.parse(dueDate) {
            Text(date.formatted(date: .omitted, time: .shortened))
                .font(Tokens.Font.rowTrailingValue)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        } else if !task.tags.isEmpty, let tag = task.tags.first {
            WidgetBadge(text: tag)
        }
    }

    private func taskSubtitle(_ task: TickTickTask) -> String? {
        var parts: [String] = []
        if task.subtaskCount > 0 {
            parts.append("\(task.subtaskCount) subtasks")
        }
        if task.tags.count > 1 {
            parts.append(task.tags.dropFirst().prefix(1).joined(separator: ", "))
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private func priorityColor(_ priority: TickTickPriority) -> Color {
        switch priority {
        case .none: Tokens.neutral
        case .low: Tokens.info
        case .medium: Tokens.caution
        case .high: Tokens.negative
        }
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
            Circle()
                .strokeBorder(Color.secondary.opacity(Tokens.Chart.ringTrackOpacity), lineWidth: Tokens.Chart.ringWidth)

            Circle()
                .trim(from: 0, to: fraction)
                .stroke(Tokens.accent, style: StrokeStyle(lineWidth: Tokens.Chart.ringWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.4), value: fraction)

            Text("\(completed)/\(total)")
                .font(Tokens.Font.microLabel.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .frame(width: Tokens.Size.progressRing, height: Tokens.Size.progressRing)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Task progress")
        .accessibilityValue("\(completed) of \(total) complete")
    }
}

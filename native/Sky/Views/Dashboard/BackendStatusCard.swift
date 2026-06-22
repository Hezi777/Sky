import SwiftUI

struct BackendStatusCard: View {
    let state: BackendRuntimeState
    let onRetry: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        WidgetShell(title: "Sky Service", symbol: "bolt.horizontal.circle", tint: Tokens.warning) {
            HStack(spacing: Tokens.contentSpacing) {
                CloudAvatar(state: .droopy, size: Tokens.Size.statusCharacter)
                BackendStatusMessage(state: state)
                Spacer(minLength: Tokens.snug)
                BackendStatusActions(
                    isStarting: state == .starting,
                    canRetry: state != .disabled,
                    onRetry: onRetry,
                    onOpenSettings: onOpenSettings
                )
            }
        }
    }
}

struct IntegrationSetupStatusCard: View {
    let count: Int
    let onOpenSettings: () -> Void

    var body: some View {
        WidgetShell(title: "Finish Setup", symbol: "slider.horizontal.3", tint: Tokens.warning) {
            HStack(spacing: Tokens.contentSpacing) {
                CloudAvatar(state: .droopy, size: Tokens.Size.statusCharacter)
                VStack(alignment: .leading, spacing: Tokens.tight) {
                    Text("\(count) \(count == 1 ? "integration needs" : "integrations need") setup")
                        .font(Tokens.Font.bodyRowStrong)
                    Text("Configured widgets are ready. Finish setup when you want to connect the rest.")
                        .font(Tokens.Font.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: Tokens.snug)
                Button("Open Settings", action: onOpenSettings)
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}

struct WidgetSetupCard: View {
    let kind: WidgetKind

    var body: some View {
        WidgetShell(title: kind.title, symbol: kind.symbol, tint: Tokens.textSecondary) {
            EmptyHint(text: "Connect \(kind.title) in Settings")
        }
    }
}

private struct BackendStatusMessage: View {
    let state: BackendRuntimeState

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.tight) {
            Text(title)
                .font(Tokens.Font.bodyRowStrong)
            Text(detail)
                .font(Tokens.Font.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
    }

    private var title: String {
        switch state {
        case .starting: "Waking up your dashboard…"
        case .disabled: "Local integrations are off on iOS"
        case .failed: "Sky's local service needs attention"
        case .idle: "Sky's local service is paused"
        case .ready: "Sky is connected"
        }
    }

    private var detail: String {
        switch state {
        case .starting: "Your local integrations will appear as soon as the private service is ready."
        case .disabled: "Weather, quotes, and countdowns still work. Remote integrations are intentionally unavailable in this version."
        case .failed(let message): message
        case .idle: "Start the service to load Calendar, Tasks, Finance, and activity data."
        case .ready: "Your integrations are available."
        }
    }
}

private struct BackendStatusActions: View {
    let isStarting: Bool
    let canRetry: Bool
    let onRetry: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        HStack(spacing: Tokens.snug) {
            Button("Settings", action: onOpenSettings)
            if canRetry {
                Button(action: onRetry) {
                    if isStarting {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text("Retry")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isStarting)
            }
        }
    }
}

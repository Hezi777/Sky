import SwiftUI

struct SpotifyWidget: View {
    @Environment(DashboardStore.self) private var store
    @Environment(\.widgetSize) private var size

    var body: some View {
        AsyncCard(
            title: "Spotify",
            symbol: "music.note",
            tint: Tokens.positive,
            state: store.spotify,
            isEmpty: { $0.nowPlaying == nil && $0.recent.isEmpty },
            emptyText: "Nothing playing",
            reload: { await store.load(.spotify, force: true) }
        ) { response in
            VStack(alignment: .leading, spacing: Tokens.contentSpacing) {
                if let np = response.nowPlaying {
                    NowPlayingBlock(nowPlaying: np)
                } else {
                    NothingPlayingHint()
                }

                if !response.recent.isEmpty, recentCount > 0 {
                    RecentSection(tracks: Array(response.recent.prefix(recentCount)))
                }
            }
        }
        .task { await store.load(.spotify) }
    }

    /// How many recent tracks actually fit.
    ///
    /// `size` was read here but never used, so every tile drew three rows —
    /// and a medium tile is only one row unit tall, so the now-playing block
    /// plus a three-row list overflowed and was cut mid-track by the hard
    /// height clamp in DashboardView. Only the two-row large tile has room for
    /// the full list.
    private var recentCount: Int {
        switch size {
        case .large: 3
        case .medium: 1
        default: 0
        }
    }
}

// MARK: - Now Playing

private struct NowPlayingBlock: View {
    let nowPlaying: SpotifyNowPlaying

    var body: some View {
        let content = HStack(spacing: Tokens.contentSpacing) {
            AsyncImage(url: nowPlaying.albumArt.flatMap(URL.init)) { image in
                image.resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: Tokens.mediaRadius, style: .continuous)
                    .fill(.fill.tertiary)
            }
            .frame(width: Tokens.Size.artwork, height: Tokens.Size.artwork)
            .clipShape(RoundedRectangle(cornerRadius: Tokens.mediaRadius, style: .continuous))
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Tokens.tight) {
                HStack(spacing: Tokens.sectionSpacing) {
                    if nowPlaying.isPlaying {
                        EqualizerIndicator(isPlaying: true)
                    }
                    Text(nowPlaying.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                }
                Text(nowPlaying.artist)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if nowPlaying.isPlaying && nowPlaying.durationMs > 0 {
                    WidgetProgressBar(progress: progressFraction, tint: Tokens.positive)
                } else if !nowPlaying.isPlaying {
                    Text("Paused")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .contentShape(Rectangle())

        if let url = URL(string: nowPlaying.url) {
            Link(destination: url) {
                content
            }
            .buttonStyle(.plain)
        } else {
            content
        }
    }

    private var progressFraction: Double {
        guard nowPlaying.durationMs > 0 else { return 0 }
        return min(1, Double(nowPlaying.progressMs) / Double(nowPlaying.durationMs))
    }
}

// MARK: - Nothing playing placeholder

private struct NothingPlayingHint: View {
    var body: some View {
        HStack(spacing: Tokens.contentSpacing) {
            ZStack {
                RoundedRectangle(cornerRadius: Tokens.mediaRadius, style: .continuous)
                    .fill(.fill.tertiary)
                    .frame(width: Tokens.Size.artwork, height: Tokens.Size.artwork)
                Image(systemName: "music.note")
                    .foregroundStyle(.secondary)
                    .font(.title3)
            }
            Text("Nothing playing right now")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Recent tracks section

private struct RecentSection: View {
    let tracks: [SpotifyTrack]

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionSpacing) {
            Divider()

            WidgetSectionHeader(title: "Recently played")

            VStack(spacing: Tokens.zeroSpacing) {
                ForEach(Array(tracks.enumerated()), id: \.element.id) { index, track in
                    RecentTrackRow(track: track, showsDivider: index < tracks.count - 1)
                }
            }
        }
    }
}

// MARK: - Recent track row

private struct RecentTrackRow: View {
    let track: SpotifyTrack
    var showsDivider: Bool = true

    var body: some View {
        let row = WidgetRow(
            title: track.title,
            subtitle: track.artist,
            showsDivider: showsDivider,
            leading: {
                AsyncImage(url: track.albumArt.flatMap(URL.init)) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: Tokens.mediaRadius, style: .continuous)
                        .fill(.fill.tertiary)
                }
                .frame(width: Tokens.Size.recentArtwork, height: Tokens.Size.recentArtwork)
                .clipShape(RoundedRectangle(cornerRadius: Tokens.mediaRadius, style: .continuous))
            }
        )

        if let url = URL(string: track.url) {
            Link(destination: url) {
                row
            }
            .buttonStyle(.plain)
        } else {
            row
        }
    }
}

// MARK: - Equalizer indicator

private struct EqualizerIndicator: View {
    let isPlaying: Bool

    var body: some View {
        HStack(spacing: Tokens.equalizerSpacing) {
            ForEach(0..<3, id: \.self) { i in
                RoundedRectangle(cornerRadius: Tokens.hairlineRadius)
                    .fill(Tokens.positive)
                    .frame(width: Tokens.Size.hairlineBar, height: isPlaying ? barHeight(i) : Tokens.Size.progressBar)
            }
        }
        .frame(width: Tokens.Size.compactControl, height: Tokens.Size.compactControl)
    }

    private func barHeight(_ index: Int) -> CGFloat {
        switch index {
        case 0: return Tokens.snug
        case 1: return Tokens.Size.compactControl
        default: return Tokens.sectionSpacing
        }
    }
}

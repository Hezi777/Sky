import SwiftUI

struct SpotifyWidget: View {
    var body: some View {
        AsyncCard(
            title: "Spotify",
            symbol: "music.note",
            tint: Tokens.positive,
            load: { try await APIClient.shared.get("/api/spotify") as SpotifyResponse },
            isEmpty: { $0.nowPlaying == nil && $0.recent.isEmpty },
            emptyText: "Nothing playing"
        ) { response in
            VStack(alignment: .leading, spacing: Tokens.contentSpacing) {
                if let np = response.nowPlaying {
                    NowPlayingBlock(nowPlaying: np)
                } else {
                    NothingPlayingHint()
                }

                if !response.recent.isEmpty {
                    RecentSection(tracks: Array(response.recent.prefix(3)))
                }
            }
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
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: Tokens.mediaRadius, style: .continuous))

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
                    ProgressBar(progress: progressFraction)
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
                    .frame(width: 56, height: 56)
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
            Text("Recently played")
                .font(.caption2.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
                .padding(.top, Tokens.extraTight)

            VStack(spacing: Tokens.extraTight) {
                ForEach(tracks) { track in
                    RecentTrackRow(track: track)
                }
            }
        }
    }
}

// MARK: - Recent track row

private struct RecentTrackRow: View {
    let track: SpotifyTrack

    var body: some View {
        let content = HStack(spacing: Tokens.rowSpacing) {
            AsyncImage(url: track.albumArt.flatMap(URL.init)) { image in
                image.resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: Tokens.compactRadius, style: .continuous)
                    .fill(.fill.tertiary)
            }
            .frame(width: 32, height: 32)
            .clipShape(RoundedRectangle(cornerRadius: Tokens.compactRadius, style: .continuous))

            VStack(alignment: .leading, spacing: Tokens.microSpacing) {
                Text(track.title)
                    .font(.caption.weight(.medium))
                    .lineLimit(1)
                Text(track.artist)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: Tokens.snug)
        }
        .padding(.vertical, Tokens.badgePadding)
        .padding(.horizontal, Tokens.tight)
        .contentShape(Rectangle())

        if let url = URL(string: track.url) {
            Link(destination: url) {
                content
            }
            .buttonStyle(.plain)
        } else {
            content
        }
    }
}

// MARK: - Progress bar

private struct ProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            Capsule()
                .fill(.fill.tertiary)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(Tokens.positive)
                        .frame(width: geo.size.width * progress)
                }
        }
        .frame(height: 3)
        .clipShape(Capsule())
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
                    .frame(width: 2.5, height: isPlaying ? barHeight(i) : 4)
            }
        }
        .frame(width: 12, height: 12)
    }

    private func barHeight(_ index: Int) -> CGFloat {
        switch index {
        case 0: return 8
        case 1: return 12
        default: return 6
        }
    }
}

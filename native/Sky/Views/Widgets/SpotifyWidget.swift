import SwiftUI

struct SpotifyWidget: View {
    var body: some View {
        AsyncCard(
            title: "Spotify",
            symbol: "music.note",
            tint: .green,
            load: { try await APIClient.shared.get("/api/spotify") as SpotifyResponse },
            isEmpty: { $0.nowPlaying == nil && $0.recent.isEmpty },
            emptyText: "Nothing playing"
        ) { response in
            VStack(alignment: .leading, spacing: 12) {
                if let np = response.nowPlaying {
                    NowPlayingRow(nowPlaying: np)
                }

                if !response.recent.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(response.recent.prefix(4)) { track in
                            RecentTrackRow(track: track)
                        }
                    }
                }
            }
        }
    }
}

private struct NowPlayingRow: View {
    let nowPlaying: SpotifyNowPlaying

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: nowPlaying.albumArt.flatMap(URL.init)) { image in
                image.resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.fill.tertiary)
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    EqualizerIndicator(isPlaying: nowPlaying.isPlaying)
                    Text(nowPlaying.title)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                }
                Text(nowPlaying.artist)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                ProgressBar(progress: progressFraction)
            }
        }
    }

    private var progressFraction: Double {
        guard nowPlaying.durationMs > 0 else { return 0 }
        return min(1, Double(nowPlaying.progressMs) / Double(nowPlaying.durationMs))
    }
}

private struct ProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            Capsule()
                .fill(.fill.tertiary)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(.green)
                        .frame(width: geo.size.width * progress)
                }
        }
        .frame(height: 3)
        .clipShape(Capsule())
    }
}

private struct EqualizerIndicator: View {
    let isPlaying: Bool

    var body: some View {
        HStack(spacing: 1.5) {
            ForEach(0..<3, id: \.self) { i in
                RoundedRectangle(cornerRadius: 0.5)
                    .fill(.green)
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

private struct RecentTrackRow: View {
    let track: SpotifyTrack

    var body: some View {
        HStack(spacing: 10) {
            AsyncImage(url: track.albumArt.flatMap(URL.init)) { image in
                image.resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(.fill.tertiary)
            }
            .frame(width: 32, height: 32)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Text(track.title)
                    .font(.caption.weight(.medium))
                    .lineLimit(1)
                Text(track.artist)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)
        }
    }
}

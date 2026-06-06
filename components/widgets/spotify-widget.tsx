"use client";

import Image from "next/image";
import { SiSpotify } from "react-icons/si";
import useSWR from "swr";

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Progress } from "@/components/ui/progress";
import { Skeleton } from "@/components/ui/skeleton";
import { fetcher } from "@/lib/fetcher";
import type { SpotifyResponse, SpotifyTrack } from "@/lib/types";

// Convert a web URL (https://open.spotify.com/track/ID) to a spotify: app URI
// so links open the desktop/mobile app instead of the website. Falls back to
// the original URL if the shape is unexpected.
function toSpotifyAppUri(webUrl: string): string {
  const m = webUrl.match(
    /open\.spotify\.com\/(track|album|artist|playlist|episode|show)\/([A-Za-z0-9]+)/,
  );
  return m ? `spotify:${m[1]}:${m[2]}` : webUrl;
}

// CSS-only animated equalizer bars shown while a track is playing.
function EqualizerBars() {
  return (
    <span className="flex items-end gap-[2px]" aria-hidden>
      {[1, 2, 3].map((i) => (
        <span
          key={i}
          className="w-[3px] rounded-sm bg-[#1DB954]"
          style={{
            height: i === 2 ? "12px" : "8px",
            animation: `eq-bounce 0.8s ease-in-out ${(i - 1) * 0.15}s infinite alternate`,
          }}
        />
      ))}
      <style>{`
        @keyframes eq-bounce {
          from { transform: scaleY(0.3); }
          to   { transform: scaleY(1); }
        }
      `}</style>
    </span>
  );
}

function SpotifyWidgetSkeleton() {
  return (
    <Card className="flex h-full flex-col rounded-2xl">
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <SiSpotify className="text-[#1DB954]" size={18} />
          Spotify
        </CardTitle>
      </CardHeader>
      <CardContent className="flex flex-1 flex-col space-y-4">
        {/* Now playing skeleton */}
        <div className="flex items-center gap-3">
          <Skeleton className="size-14 rounded-xl flex-shrink-0" />
          <div className="flex-1 space-y-2">
            <Skeleton className="h-4 w-3/4" />
            <Skeleton className="h-3 w-1/2" />
            <Skeleton className="h-1 w-full" />
          </div>
        </div>
        {/* Recent tracks skeleton */}
        <div className="space-y-2 pt-2">
          {[1, 2, 3, 4].map((i) => (
            <div key={i} className="flex items-center gap-2">
              <Skeleton className="size-8 rounded flex-shrink-0" />
              <div className="flex-1 space-y-1">
                <Skeleton className="h-3 w-2/3" />
                <Skeleton className="h-2.5 w-1/2" />
              </div>
            </div>
          ))}
        </div>
      </CardContent>
    </Card>
  );
}

function RecentTrackRow({ track }: { track: SpotifyTrack }) {
  return (
    <a
      href={toSpotifyAppUri(track.url)}
      className="flex items-center gap-2 rounded-lg p-1 transition-colors hover:bg-muted/60"
    >
      {track.albumArt ? (
        <Image
          src={track.albumArt}
          alt={track.title}
          width={32}
          height={32}
          className="size-8 rounded flex-shrink-0 object-cover"
          unoptimized
        />
      ) : (
        <div className="size-8 rounded bg-muted flex-shrink-0" />
      )}
      <div className="min-w-0 flex-1">
        <p className="truncate text-xs font-medium leading-tight">{track.title}</p>
        <p className="truncate text-xs text-muted-foreground leading-tight">{track.artist}</p>
      </div>
    </a>
  );
}

export function SpotifyWidget() {
  const { data, error, isLoading } = useSWR<SpotifyResponse>(
    "/api/spotify",
    fetcher<SpotifyResponse>,
    { refreshInterval: 30_000 }
  );

  if (isLoading) return <SpotifyWidgetSkeleton />;

  if (error || !data) {
    return (
      <Card className="flex h-full flex-col rounded-2xl">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <SiSpotify className="text-[#1DB954]" size={18} />
            Spotify
          </CardTitle>
        </CardHeader>
        <CardContent>
          <p className="text-sm text-muted-foreground">
            {error?.message ?? "Could not load Spotify data."}
          </p>
        </CardContent>
      </Card>
    );
  }

  const { nowPlaying, recent } = data;
  const progressPercent =
    nowPlaying && nowPlaying.durationMs > 0
      ? Math.round((nowPlaying.progressMs / nowPlaying.durationMs) * 100)
      : 0;

  return (
    <Card className="flex h-full flex-col rounded-2xl">
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <SiSpotify className="text-[#1DB954]" size={18} />
          Spotify
          {nowPlaying?.isPlaying && (
            <span className="ml-auto">
              <EqualizerBars />
            </span>
          )}
        </CardTitle>
      </CardHeader>

      <CardContent className="flex flex-1 flex-col space-y-4">
        {/* Now playing */}
        {nowPlaying ? (
          <a
            href={toSpotifyAppUri(nowPlaying.url)}
            className="flex items-start gap-3 rounded-xl p-1 transition-colors hover:bg-muted/60"
          >
            {nowPlaying.albumArt ? (
              <Image
                src={nowPlaying.albumArt}
                alt={nowPlaying.title}
                width={56}
                height={56}
                className="size-14 rounded-xl flex-shrink-0 object-cover"
                unoptimized
              />
            ) : (
              <div className="size-14 rounded-xl bg-muted flex-shrink-0" />
            )}
            <div className="min-w-0 flex-1 space-y-1 pt-0.5">
              <p className="truncate text-sm font-semibold leading-tight">{nowPlaying.title}</p>
              <p className="truncate text-xs text-muted-foreground">{nowPlaying.artist}</p>
              {nowPlaying.isPlaying && nowPlaying.durationMs > 0 && (
                <Progress
                  value={progressPercent}
                  className="mt-1"
                />
              )}
              {!nowPlaying.isPlaying && (
                <p className="text-xs text-muted-foreground">Paused</p>
              )}
            </div>
          </a>
        ) : (
          <div className="flex items-center gap-3 rounded-xl p-1">
            <div className="flex size-14 items-center justify-center rounded-xl bg-muted flex-shrink-0">
              <SiSpotify className="text-muted-foreground" size={24} />
            </div>
            <p className="text-sm text-muted-foreground">Nothing playing right now</p>
          </div>
        )}

        {/* Recent tracks */}
        {recent.length > 0 && (
          <div className="mt-auto space-y-0.5 border-t border-border pt-3">
            <p className="mb-1.5 text-xs font-medium text-muted-foreground uppercase tracking-wide">
              Recently played
            </p>
            {recent.slice(0, 3).map((track, i) => (
              <RecentTrackRow key={`${track.url}-${i}`} track={track} />
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  );
}

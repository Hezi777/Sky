import type { SpotifyNowPlaying, SpotifyResponse, SpotifyTrack } from "@/lib/types";

async function getAccessToken(): Promise<string> {
  const clientId = process.env.SPOTIFY_CLIENT_ID;
  const clientSecret = process.env.SPOTIFY_CLIENT_SECRET;
  const refreshToken = process.env.SPOTIFY_REFRESH_TOKEN;

  if (!clientId || !clientSecret || !refreshToken) {
    throw new Error("Missing Spotify credentials");
  }

  const credentials = Buffer.from(`${clientId}:${clientSecret}`).toString("base64");

  const res = await fetch("https://accounts.spotify.com/api/token", {
    method: "POST",
    headers: {
      Authorization: `Basic ${credentials}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: `grant_type=refresh_token&refresh_token=${encodeURIComponent(refreshToken)}`,
  });

  if (!res.ok) {
    const text = await res.text().catch(() => res.status.toString());
    throw new Error(`Token exchange failed: ${text}`);
  }

  const data = (await res.json()) as { access_token: string };
  return data.access_token;
}

function mapTrack(item: SpotifyApiTrack): SpotifyTrack {
  return {
    title: item.name,
    artist: item.artists.map((a) => a.name).join(", "),
    albumArt: item.album?.images?.[0]?.url ?? null,
    url: item.external_urls?.spotify ?? "",
  };
}

// Minimal Spotify API shapes — only the fields we actually use.
interface SpotifyApiTrack {
  name: string;
  artists: { name: string }[];
  album?: { images?: { url: string }[] };
  external_urls?: { spotify?: string };
  duration_ms?: number;
}

interface NowPlayingApiResponse {
  is_playing: boolean;
  progress_ms: number;
  item: SpotifyApiTrack | null;
}

interface RecentlyPlayedApiResponse {
  items: { track: SpotifyApiTrack }[];
}

export async function getNowPlaying(accessToken: string): Promise<SpotifyNowPlaying | null> {
  const res = await fetch("https://api.spotify.com/v1/me/player/currently-playing", {
    headers: { Authorization: `Bearer ${accessToken}` },
  });

  // 204 = nothing playing
  if (res.status === 204 || res.status === 205) return null;

  if (!res.ok) {
    throw new Error(`currently-playing failed: ${res.status}`);
  }

  const data = (await res.json()) as NowPlayingApiResponse;

  if (!data?.item) return null;

  return {
    ...mapTrack(data.item),
    isPlaying: data.is_playing,
    progressMs: data.progress_ms ?? 0,
    durationMs: data.item.duration_ms ?? 0,
  };
}

export async function getRecent(accessToken: string): Promise<SpotifyTrack[]> {
  const res = await fetch("https://api.spotify.com/v1/me/player/recently-played?limit=4", {
    headers: { Authorization: `Bearer ${accessToken}` },
  });

  if (!res.ok) {
    throw new Error(`recently-played failed: ${res.status}`);
  }

  const data = (await res.json()) as RecentlyPlayedApiResponse;
  return (data.items ?? []).map((item) => mapTrack(item.track));
}

export async function getSpotifyData(): Promise<SpotifyResponse> {
  const accessToken = await getAccessToken();
  const [nowPlaying, recent] = await Promise.all([
    getNowPlaying(accessToken),
    getRecent(accessToken),
  ]);
  return { nowPlaying, recent };
}

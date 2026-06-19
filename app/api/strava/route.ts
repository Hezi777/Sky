import { NextResponse } from "next/server";

export const dynamic = "force-dynamic";

interface StravaActivity {
  id: number;
  name: string;
  type: string;
  distance: number; // meters
  movingTime: number; // seconds
  startDate: string; // ISO
}

interface StravaTokenResponse {
  access_token: string;
}

interface StravaRawActivity {
  id: number;
  name: string;
  type: string;
  distance: number;
  moving_time: number;
  start_date: string;
}

export async function GET() {
  const clientId = process.env.STRAVA_CLIENT_ID;
  const clientSecret = process.env.STRAVA_CLIENT_SECRET;
  const refreshToken = process.env.STRAVA_REFRESH_TOKEN;

  if (!clientId || !clientSecret || !refreshToken) {
    return NextResponse.json(
      { error: "Strava not connected" },
      { status: 200 }
    );
  }

  try {
    // Exchange the long-lived refresh token for a short-lived access token.
    const tokenRes = await fetch("https://www.strava.com/oauth/token", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        client_id: clientId,
        client_secret: clientSecret,
        grant_type: "refresh_token",
        refresh_token: refreshToken,
      }),
      cache: "no-store",
    });
    if (!tokenRes.ok) throw new Error(`Strava token ${tokenRes.status}`);
    const token = (await tokenRes.json()) as StravaTokenResponse;

    const actRes = await fetch(
      "https://www.strava.com/api/v3/athlete/activities?per_page=5",
      {
        headers: { Authorization: `Bearer ${token.access_token}` },
        cache: "no-store",
      }
    );
    if (!actRes.ok) throw new Error(`Strava activities ${actRes.status}`);
    const raw = (await actRes.json()) as StravaRawActivity[];

    const activities: StravaActivity[] = raw.map((a) => ({
      id: a.id,
      name: a.name,
      type: a.type,
      distance: a.distance,
      movingTime: a.moving_time,
      startDate: a.start_date,
    }));

    return NextResponse.json(activities);
  } catch (err) {
    const message = err instanceof Error ? err.message : "Unknown error";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}

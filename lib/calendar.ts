import type { CalendarEvent } from "@/lib/types";

async function getAccessToken(): Promise<string> {
  const params = new URLSearchParams({
    client_id: process.env.GOOGLE_CLIENT_ID ?? "",
    client_secret: process.env.GOOGLE_CLIENT_SECRET ?? "",
    refresh_token: process.env.GOOGLE_REFRESH_TOKEN ?? "",
    grant_type: "refresh_token",
  });

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: params.toString(),
  });

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`Token refresh failed (${res.status}): ${body}`);
  }

  const data = (await res.json()) as { access_token: string };
  return data.access_token;
}

export async function getUpcomingEvents(): Promise<CalendarEvent[]> {
  const accessToken = await getAccessToken();

  const url = new URL(
    "https://www.googleapis.com/calendar/v3/calendars/primary/events"
  );
  url.searchParams.set("timeMin", new Date().toISOString());
  url.searchParams.set("maxResults", "5");
  url.searchParams.set("orderBy", "startTime");
  url.searchParams.set("singleEvents", "true");

  const res = await fetch(url.toString(), {
    headers: { Authorization: `Bearer ${accessToken}` },
  });

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`Calendar fetch failed (${res.status}): ${body}`);
  }

  const data = (await res.json()) as {
    items: Array<{
      id: string;
      summary?: string;
      start: { dateTime?: string; date?: string };
      end: { dateTime?: string; date?: string };
      location?: string;
      colorId?: string;
    }>;
  };

  return (data.items ?? []).map((item) => {
    const allDay = !item.start.dateTime;
    return {
      id: item.id,
      title: item.summary ?? "(No title)",
      start: item.start.dateTime ?? item.start.date ?? "",
      end: item.end.dateTime ?? item.end.date ?? "",
      allDay,
      location: item.location ?? null,
      colorId: item.colorId ?? null,
    };
  });
}

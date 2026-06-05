"use client";

import useSWR from "swr";
import { Calendar, MapPin } from "lucide-react";

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { fetcher } from "@/lib/fetcher";
import type { CalendarEvent } from "@/lib/types";

// Google Calendar colorId → Tailwind/hex color dot
// https://developers.google.com/calendar/api/v3/reference/colors
const COLOR_MAP: Record<string, string> = {
  "1": "#7986cb", // Lavender
  "2": "#33b679", // Sage
  "3": "#8e24aa", // Grape
  "4": "#e67c73", // Flamingo
  "5": "#f6bf26", // Banana
  "6": "#f4511e", // Tangerine
  "7": "#039be5", // Peacock
  "8": "#616161", // Graphite
  "9": "#3f51b5", // Blueberry
  "10": "#0b8043", // Basil
  "11": "#d50000", // Tomato
};
const DEFAULT_COLOR = "#94a3b8"; // slate-400

function eventDotColor(colorId: string | null): string {
  return colorId ? (COLOR_MAP[colorId] ?? DEFAULT_COLOR) : DEFAULT_COLOR;
}

// Relative time helper — no external library
function formatEventTime(event: CalendarEvent): string {
  if (event.allDay) {
    const eventDate = new Date(event.start);
    const today = new Date();
    // Normalise to midnight local time for day comparison
    const todayMidnight = new Date(
      today.getFullYear(),
      today.getMonth(),
      today.getDate()
    );
    const eventMidnight = new Date(
      eventDate.getFullYear(),
      eventDate.getMonth(),
      eventDate.getDate()
    );
    const diffDays = Math.round(
      (eventMidnight.getTime() - todayMidnight.getTime()) / 86_400_000
    );
    if (diffDays === 0) return "Today (all day)";
    if (diffDays === 1) return "Tomorrow (all day)";
    return (
      eventDate.toLocaleDateString(undefined, { weekday: "long" }) +
      " (all day)"
    );
  }

  const start = new Date(event.start);
  const now = new Date();
  const diffMs = start.getTime() - now.getTime();
  const diffMin = Math.round(diffMs / 60_000);

  if (diffMin < 0) {
    // Already started
    const endDiff = new Date(event.end).getTime() - now.getTime();
    if (endDiff > 0) return "Now";
    return "Ended";
  }

  if (diffMin < 60) return `in ${diffMin}m`;
  if (diffMin < 120) return "in 1h";
  if (diffMin < 1440) {
    const h = Math.floor(diffMin / 60);
    return `in ${h}h`;
  }

  // More than a day away
  const timeStr = start.toLocaleTimeString(undefined, {
    hour: "2-digit",
    minute: "2-digit",
  });
  const todayMidnight = new Date(
    now.getFullYear(),
    now.getMonth(),
    now.getDate()
  );
  const startMidnight = new Date(
    start.getFullYear(),
    start.getMonth(),
    start.getDate()
  );
  const diffDays = Math.round(
    (startMidnight.getTime() - todayMidnight.getTime()) / 86_400_000
  );
  if (diffDays === 1) return `Tomorrow ${timeStr}`;
  const weekday = start.toLocaleDateString(undefined, { weekday: "short" });
  return `${weekday} ${timeStr}`;
}

export function CalendarWidget() {
  const { data, error, isLoading } = useSWR<CalendarEvent[]>(
    "/api/calendar",
    fetcher
  );

  return (
    <Card className="flex h-full flex-col rounded-2xl">
      <CardHeader className="flex flex-row items-center gap-2 pb-2">
        <Calendar className="size-4 text-muted-foreground" />
        <CardTitle className="text-sm font-medium">Calendar</CardTitle>
      </CardHeader>

      <CardContent className="min-h-0 flex-1 space-y-1 overflow-y-auto">
        {isLoading && (
          <ul className="space-y-2">
            {Array.from({ length: 3 }).map((_, i) => (
              <li key={i} className="flex items-center gap-2">
                <Skeleton className="size-2 shrink-0 rounded-full" />
                <Skeleton className="h-4 w-2/3" />
                <Skeleton className="ml-auto h-4 w-12" />
              </li>
            ))}
          </ul>
        )}

        {error && (
          <div className="flex items-center gap-2 text-sm text-destructive">
            <Calendar className="size-4 shrink-0" />
            <span>Could not load calendar</span>
          </div>
        )}

        {!isLoading && !error && data && data.length === 0 && (
          <p className="text-sm text-muted-foreground">No upcoming events</p>
        )}

        {!isLoading && !error && data && data.length > 0 && (
          <ul className="space-y-2">
            {data.map((event) => (
              <li key={event.id} className="flex items-start gap-2 text-sm">
                {/* Colored dot */}
                <span
                  className="mt-1.5 size-2 shrink-0 rounded-full"
                  style={{ backgroundColor: eventDotColor(event.colorId) }}
                  aria-hidden="true"
                />

                <div className="min-w-0 flex-1">
                  <p className="truncate font-medium leading-snug">
                    {event.title}
                  </p>
                  {event.location && (
                    <p className="flex items-center gap-1 truncate text-xs text-muted-foreground">
                      <MapPin className="size-3 shrink-0" />
                      {event.location}
                    </p>
                  )}
                </div>

                <span className="shrink-0 text-xs text-muted-foreground">
                  {formatEventTime(event)}
                </span>
              </li>
            ))}
          </ul>
        )}
      </CardContent>
    </Card>
  );
}

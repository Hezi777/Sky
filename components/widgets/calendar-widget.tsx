"use client";

import { useEffect, useState } from "react";
import useSWR from "swr";
import { Calendar, MapPin, Clock } from "lucide-react";

import { BrandLogo } from "@/components/brand-logo";

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Separator } from "@/components/ui/separator";
import { ScrollArea } from "@/components/ui/scroll-area";
import {
  Tooltip,
  TooltipContent,
  TooltipTrigger,
} from "@/components/ui/tooltip";
import { Skeleton } from "@/components/ui/skeleton";
import { fetcher } from "@/lib/fetcher";
import type { CalendarEvent } from "@/lib/types";

// Google Calendar colorId → accent hex.
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

function eventAccent(colorId: string | null): string {
  return colorId ? (COLOR_MAP[colorId] ?? DEFAULT_COLOR) : DEFAULT_COLOR;
}

function startOfDay(d: Date): Date {
  return new Date(d.getFullYear(), d.getMonth(), d.getDate());
}

function dayDiff(a: Date, b: Date): number {
  return Math.round(
    (startOfDay(a).getTime() - startOfDay(b).getTime()) / 86_400_000
  );
}

function dayLabel(date: Date, now: Date): string {
  const diff = dayDiff(date, now);
  if (diff === 0) return "Today";
  if (diff === 1) return "Tomorrow";
  if (diff === -1) return "Yesterday";
  if (diff > 1 && diff < 7)
    return date.toLocaleDateString(undefined, { weekday: "long" });
  return date.toLocaleDateString(undefined, {
    weekday: "long",
    month: "short",
    day: "numeric",
  });
}

function timeStr(d: Date): string {
  return d.toLocaleTimeString(undefined, {
    hour: "numeric",
    minute: "2-digit",
  });
}

// Short relative label. Computed client-side after mount to avoid hydration drift.
function relativeLabel(event: CalendarEvent, now: Date): string {
  if (event.allDay) return "All day";

  const start = new Date(event.start);
  const end = new Date(event.end);
  const diffMin = Math.round((start.getTime() - now.getTime()) / 60_000);

  if (diffMin < 0) {
    if (end.getTime() > now.getTime()) return "Now";
    return "Ended";
  }
  if (diffMin < 60) return `in ${diffMin}m`;
  if (diffMin < 1440) {
    const h = Math.floor(diffMin / 60);
    const m = diffMin % 60;
    return m ? `in ${h}h ${m}m` : `in ${h}h`;
  }
  const days = dayDiff(start, now);
  if (days === 1) return "Tomorrow";
  return start.toLocaleDateString(undefined, { weekday: "short" });
}

function durationLabel(event: CalendarEvent): string | null {
  if (event.allDay) return null;
  const mins = Math.round(
    (new Date(event.end).getTime() - new Date(event.start).getTime()) / 60_000
  );
  if (mins <= 0) return null;
  if (mins < 60) return `${mins}m`;
  const h = Math.floor(mins / 60);
  const m = mins % 60;
  return m ? `${h}h ${m}m` : `${h}h`;
}

interface DayGroup {
  key: string;
  label: string;
  events: CalendarEvent[];
}

function groupByDay(events: CalendarEvent[], now: Date): DayGroup[] {
  const map = new Map<string, DayGroup>();
  for (const event of events) {
    const date = new Date(event.start);
    const key = startOfDay(date).toISOString();
    if (!map.has(key)) {
      map.set(key, { key, label: dayLabel(date, now), events: [] });
    }
    map.get(key)!.events.push(event);
  }
  return Array.from(map.values());
}

function EventRow({ event, now }: { event: CalendarEvent; now: Date }) {
  const accent = eventAccent(event.colorId);
  const start = new Date(event.start);
  const duration = durationLabel(event);
  const isNow = !event.allDay && relativeLabel(event, now) === "Now";

  const fullTime = event.allDay
    ? "All day"
    : `${timeStr(start)} – ${timeStr(new Date(event.end))}`;

  return (
    <Tooltip>
      <TooltipTrigger
        render={
          <div className="group flex items-stretch gap-3 rounded-lg p-2 text-left transition-colors hover:bg-muted/60" />
        }
      >
          {/* Time block */}
          <div className="flex w-14 shrink-0 flex-col items-end pt-0.5">
            {event.allDay ? (
              <Badge
                variant="secondary"
                className="px-1.5 py-0 text-[10px] font-medium"
              >
                all-day
              </Badge>
            ) : (
              <>
                <span className="text-sm font-semibold leading-none tabular-nums text-foreground">
                  {timeStr(start)}
                </span>
                {duration && (
                  <span className="mt-1 text-[10px] leading-none text-muted-foreground">
                    {duration}
                  </span>
                )}
              </>
            )}
          </div>

          {/* Accent bar */}
          <span
            className="w-1 shrink-0 rounded-full"
            style={{ backgroundColor: accent }}
            aria-hidden="true"
          />

          {/* Details */}
          <div className="min-w-0 flex-1">
            <div className="flex items-center gap-2">
              <p className="truncate text-sm font-medium leading-snug text-foreground">
                {event.title}
              </p>
              {isNow && (
                <span className="shrink-0 rounded-full bg-emerald-500/15 px-1.5 py-0.5 text-[10px] font-semibold uppercase tracking-wide text-emerald-600 dark:text-emerald-400">
                  Now
                </span>
              )}
            </div>
            {event.location && (
              <p className="mt-0.5 flex items-center gap-1 truncate text-xs text-muted-foreground">
                <MapPin className="size-3 shrink-0" />
                <span className="truncate">{event.location}</span>
              </p>
            )}
          </div>

          {/* Relative timing */}
          <span className="shrink-0 self-start whitespace-nowrap pt-0.5 text-[11px] font-medium text-muted-foreground">
            {relativeLabel(event, now)}
          </span>
      </TooltipTrigger>
      <TooltipContent side="left" className="max-w-xs">
        <p className="font-medium">{event.title}</p>
        <p className="mt-1 flex items-center gap-1 text-xs">
          <Clock className="size-3" />
          {fullTime}
        </p>
        {event.location && (
          <p className="mt-0.5 flex items-center gap-1 text-xs">
            <MapPin className="size-3" />
            {event.location}
          </p>
        )}
      </TooltipContent>
    </Tooltip>
  );
}

export function CalendarWidget() {
  const { data, error, isLoading } = useSWR<CalendarEvent[]>(
    "/api/calendar",
    fetcher
  );

  // Pin "now" after mount so relative labels never mismatch SSR.
  const [now, setNow] = useState<Date | null>(null);
  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setNow(new Date());
    const id = setInterval(() => setNow(new Date()), 60_000);
    return () => clearInterval(id);
  }, []);

  const ready = !isLoading && !error && data && now;
  const groups = ready ? groupByDay(data, now) : [];

  return (
    <Card className="flex h-full flex-col rounded-2xl">
      <CardHeader className="flex flex-row items-center gap-2 pb-2">
        <BrandLogo name="googleCalendar" className="size-4" />
        <CardTitle className="text-sm font-medium">Calendar</CardTitle>
      </CardHeader>

      <CardContent className="min-h-0 flex-1 p-0">
        {(isLoading || (!error && !now)) && (
          <div className="space-y-2 px-6 pb-4">
            {Array.from({ length: 4 }).map((_, i) => (
              <div key={i} className="flex items-stretch gap-3 p-2">
                <Skeleton className="h-4 w-10 shrink-0" />
                <Skeleton className="w-1 shrink-0 rounded-full" />
                <div className="flex-1 space-y-1.5">
                  <Skeleton className="h-4 w-2/3" />
                  <Skeleton className="h-3 w-1/3" />
                </div>
              </div>
            ))}
          </div>
        )}

        {error && (
          <div className="flex items-center gap-2 px-6 pb-4 text-sm text-destructive">
            <Calendar className="size-4 shrink-0" />
            <span>Could not load calendar</span>
          </div>
        )}

        {ready && data.length === 0 && (
          <p className="px-6 pb-4 text-sm text-muted-foreground">
            No upcoming events
          </p>
        )}

        {ready && data.length > 0 && (
          <ScrollArea className="h-full">
            <div className="space-y-4 px-4 pb-4">
              {groups.map((group) => (
                <div key={group.key}>
                  <div className="flex items-center gap-3 px-2">
                    <span className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">
                      {group.label}
                    </span>
                    <Separator className="flex-1" />
                    <span className="text-[11px] text-muted-foreground">
                      {group.events.length}
                    </span>
                  </div>
                  <div className="mt-1 space-y-0.5">
                    {group.events.map((event) => (
                      <EventRow key={event.id} event={event} now={now} />
                    ))}
                  </div>
                </div>
              ))}
            </div>
          </ScrollArea>
        )}
      </CardContent>
    </Card>
  );
}

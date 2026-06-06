"use client";

import { useEffect, useState } from "react";
import useSWR from "swr";
import { Calendar, MapPin, Clock, ExternalLink } from "lucide-react";

import { BrandLogo } from "@/components/brand-logo";

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
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
function relativeLabel(event: CalendarEvent, now: Date): string | null {
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
  return null;
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

function timeRangeLabel(event: CalendarEvent): string {
  if (event.allDay) return "All day";
  return `${timeStr(new Date(event.start))} - ${timeStr(new Date(event.end))}`;
}

function eventState(event: CalendarEvent, now: Date): "now" | "past" | "future" {
  if (event.allDay) return "future";
  const start = new Date(event.start).getTime();
  const end = new Date(event.end).getTime();
  const current = now.getTime();

  if (start <= current && end > current) return "now";
  if (end <= current) return "past";
  return "future";
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

function EventLink({
  event,
  className,
  children,
}: {
  event: CalendarEvent;
  className: string;
  children?: React.ReactNode;
}) {
  if (!event.url) {
    return <div className={className}>{children}</div>;
  }

  return (
    <a href={event.url} target="_blank" rel="noopener noreferrer" className={className}>
      {children}
    </a>
  );
}

function EventRow({ event, now, first }: { event: CalendarEvent; now: Date; first: boolean }) {
  const accent = eventAccent(event.colorId);
  const start = new Date(event.start);
  const duration = durationLabel(event);
  const state = eventState(event, now);
  const muted = state === "past";
  const relative = relativeLabel(event, now);

  return (
    <Tooltip>
      <TooltipTrigger
        render={
          <EventLink
            event={event}
            className={[
              "group grid grid-cols-[3.9rem_1fr] gap-3 rounded-xl px-2.5 py-2.5 text-left transition-colors hover:bg-muted/45 sm:grid-cols-[4.2rem_1fr_auto]",
              first ? "bg-muted/25" : "",
              muted ? "opacity-65" : "",
            ].join(" ")}
          />
        }
      >
        <div className="pt-0.5 text-right">
          {event.allDay ? (
            <Badge variant="secondary" className="px-1.5 py-0 text-[10px] font-medium">
              all day
            </Badge>
          ) : (
            <>
              <p className="text-sm font-semibold leading-none tabular-nums text-foreground">
                {timeStr(start)}
              </p>
              {duration && <p className="mt-1 text-[10px] text-muted-foreground">{duration}</p>}
            </>
          )}
        </div>

        <div className="relative min-w-0 border-l pl-3" style={{ borderColor: accent }}>
          <span
            className="absolute -left-[5px] top-1.5 h-2.5 w-2.5 rounded-full border-2 border-card"
            style={{ backgroundColor: accent }}
            aria-hidden="true"
          />
          <div className="flex min-w-0 items-center gap-2">
            <p dir="auto" className="truncate text-start text-sm font-medium text-foreground">
              {event.title}
            </p>
            {state === "now" && (
              <span className="shrink-0 rounded-full bg-emerald-500/15 px-1.5 py-0.5 text-[10px] font-semibold uppercase tracking-wide text-emerald-600 dark:text-emerald-400">
                Now
              </span>
            )}
          </div>
          {event.location && (
            <p className="mt-0.5 flex min-w-0 items-center gap-1 text-xs text-muted-foreground">
              <MapPin className="size-3 shrink-0" />
              <span dir="auto" className="truncate text-start">
                {event.location}
              </span>
            </p>
          )}
          {(relative || event.url) && (
            <div className="mt-1 flex flex-wrap items-center gap-2 text-[11px] text-muted-foreground sm:hidden">
              {relative && <span>{relative}</span>}
              {event.url && <ExternalLink className="size-3 shrink-0" />}
            </div>
          )}
        </div>

        <div className="hidden items-center gap-2 text-[11px] font-medium text-muted-foreground sm:flex">
          {relative && <span>{relative}</span>}
          {event.url && (
            <ExternalLink className="size-3 shrink-0 opacity-0 transition-opacity group-hover:opacity-100" />
          )}
        </div>
      </TooltipTrigger>
      <TooltipContent side="left" className="max-w-xs">
        <p dir="auto" className="font-medium text-start">
          {event.title}
        </p>
        <p className="mt-1 flex items-center gap-1 text-xs">
          <Clock className="size-3" />
          {timeRangeLabel(event)}
        </p>
        {event.location && (
          <p className="mt-0.5 flex items-center gap-1 text-xs">
            <MapPin className="size-3" />
            <span dir="auto" className="text-start">
              {event.location}
            </span>
          </p>
        )}
      </TooltipContent>
    </Tooltip>
  );
}

function DayEvents({
  group,
  now,
}: {
  group: DayGroup;
  now: Date;
}) {
  return (
    <div className="grid gap-3 sm:grid-cols-[4.8rem_1fr]">
      <div className="px-2 pt-2 sm:px-0">
        <p className="text-xs font-semibold uppercase tracking-[0.16em] text-muted-foreground">
          {group.label}
        </p>
      </div>
      <div className="space-y-1">
        {group.events.map((event, index) => (
          <EventRow key={event.id} event={event} now={now} first={index === 0} />
        ))}
      </div>
    </div>
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
    <Card className="flex h-full flex-col overflow-hidden rounded-2xl">
      <CardHeader className="flex flex-row items-center justify-between gap-3 pb-3">
        <div className="flex min-w-0 items-center gap-2">
          <BrandLogo name="googleCalendar" className="size-4" />
          <CardTitle className="text-sm font-medium">Calendar</CardTitle>
        </div>
        {ready && data.length > 0 && (
          <span className="shrink-0 rounded-full border border-border bg-muted/30 px-2.5 py-1 text-xs font-medium text-muted-foreground">
            {data.length} upcoming
          </span>
        )}
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
                <DayEvents key={group.key} group={group} now={now} />
              ))}
            </div>
          </ScrollArea>
        )}
      </CardContent>
    </Card>
  );
}

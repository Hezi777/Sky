"use client";

import { useEffect, useState } from "react";
import useSWR from "swr";

import { Card } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import type { GreetingResponse } from "@/lib/types";
import { MemojiPicker } from "@/components/memoji-picker";
import { useSettings } from "@/components/settings-provider";
import { MEMOJIS } from "@/lib/memojis";

type Greeting = { word: string; emoji: string };

function greetingFor(hour: number): Greeting {
  if (hour < 12) return { word: "Good morning", emoji: "🔥" };
  if (hour < 18) return { word: "Good afternoon", emoji: "☀️" };
  return { word: "Good evening", emoji: "🌙" };
}

export function GreetingCard() {
  const { data, isLoading, error } = useSWR<GreetingResponse>(
    "/api/ai/greeting",
    () =>
      fetch("/api/ai/greeting", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ events: [], tasks: [] }),
      }).then((r) => r.json()),
    { revalidateOnFocus: false }
  );

  const { name, memojiId, ready, setMemojiId } = useSettings();

  // null until mounted so server and first client render match (no hydration mismatch).
  const [now, setNow] = useState<Date | null>(null);

  useEffect(() => {
    // Set on mount (not during render) so SSR and first client render match.
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setNow(new Date());
    const id = setInterval(() => setNow(new Date()), 60_000);
    return () => clearInterval(id);
  }, []);

  const currentMemoji = MEMOJIS.find((m) => m.id === memojiId) ?? MEMOJIS[0];

  const greeting = now ? greetingFor(now.getHours()) : null;
  const dayPercent = now
    ? Math.round(((now.getHours() * 60 + now.getMinutes()) / 1440) * 100)
    : null;

  // Ring geometry.
  const size = 80;
  const stroke = 5;
  const radius = (size - stroke) / 2;
  const circumference = 2 * Math.PI * radius;
  const dashOffset =
    dayPercent === null
      ? circumference
      : circumference * (1 - dayPercent / 100);

  return (
    <Card className="flex h-full flex-col rounded-2xl">
      <div className="flex flex-col items-center gap-5 px-6 py-2 text-center sm:flex-row sm:gap-6 sm:text-left">
        {/* Avatar + progress ring */}
        <div
          className="relative shrink-0"
          style={{ width: size, height: size }}
        >
          <svg
            width={size}
            height={size}
            viewBox={`0 0 ${size} ${size}`}
            className="-rotate-90"
            aria-hidden
          >
            <circle
              cx={size / 2}
              cy={size / 2}
              r={radius}
              fill="none"
              strokeWidth={stroke}
              className="stroke-border"
            />
            <circle
              cx={size / 2}
              cy={size / 2}
              r={radius}
              fill="none"
              strokeWidth={stroke}
              strokeLinecap="round"
              stroke="var(--primary)"
              strokeDasharray={circumference}
              strokeDashoffset={dashOffset}
              className="transition-[stroke-dashoffset] duration-700 ease-out"
            />
          </svg>

          {/* Avatar */}
          <div className="absolute inset-[7px] rounded-full overflow-hidden">
            {ready ? (
              <img
                src={currentMemoji.url}
                alt={`${name}'s memoji`}
                width={66}
                height={66}
                className="h-full w-full rounded-full object-cover"
              />
            ) : (
              // Placeholder shown before hydration (matches SSR — no mismatch)
              <div className="flex h-full w-full items-center justify-center rounded-full bg-gradient-to-br from-primary/85 to-primary text-primary-foreground">
                <span className="text-2xl font-semibold tracking-tight">
                  {name.charAt(0).toUpperCase() || "H"}
                </span>
              </div>
            )}
            {/* Picker trigger — overlays the avatar, only after hydration */}
            {ready && (
              <MemojiPicker selectedId={memojiId} onSelect={setMemojiId} />
            )}
          </div>

          {/* Percent badge */}
          <div className="absolute -right-1 -top-1 rounded-full border border-border bg-card px-1.5 py-0.5 text-[10px] font-semibold tabular-nums text-foreground shadow-sm">
            {dayPercent === null ? "—" : `${dayPercent}%`}
          </div>
        </div>

        {/* Greeting + subtitle */}
        <div className="min-w-0 flex-1">
          <h2 className="text-xl font-semibold tracking-tight text-foreground sm:text-2xl">
            {greeting ? (
              <>
                {greeting.word}, {name} <span aria-hidden>{greeting.emoji}</span>
              </>
            ) : (
              `Hello, ${name}`
            )}
          </h2>

          <div className="mt-1.5">
            {isLoading ? (
              <Skeleton className="mx-auto h-4 w-3/4 sm:mx-0" />
            ) : data?.message ? (
              <p className="text-sm text-muted-foreground">{data.message}</p>
            ) : (
              <p className="text-sm text-muted-foreground">
                {error
                  ? "Hope your day is off to a good start."
                  : "Here's to a focused day ahead."}
              </p>
            )}
          </div>
        </div>
      </div>
    </Card>
  );
}

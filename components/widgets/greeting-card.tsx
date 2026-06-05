"use client";

import { useEffect, useState } from "react";
import useSWR from "swr";

import { Card } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import type { GreetingResponse } from "@/lib/types";
import { MemojiPicker } from "@/components/memoji-picker";
import { MEMOJIS, DEFAULT_MEMOJI_ID } from "@/lib/memojis";

const STORAGE_KEY = "sky:memoji";

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

  // null until mounted so server and first client render match (no hydration mismatch).
  const [now, setNow] = useState<Date | null>(null);

  // Memoji selection — null until mounted to avoid SSR mismatch.
  const [memojiId, setMemojiId] = useState<string | null>(null);

  useEffect(() => {
    // Set on mount (not during render) so SSR and first client render match.
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setNow(new Date());
    const id = setInterval(() => setNow(new Date()), 60_000);
    return () => clearInterval(id);
  }, []);

  // Read persisted memoji on mount (localStorage is client-only).
  useEffect(() => {
    try {
      const stored = localStorage.getItem(STORAGE_KEY);
      const valid = stored && MEMOJIS.some((m) => m.id === stored);
      // eslint-disable-next-line react-hooks/set-state-in-effect
      setMemojiId(valid ? stored : DEFAULT_MEMOJI_ID);
    } catch {
      // eslint-disable-next-line react-hooks/set-state-in-effect
      setMemojiId(DEFAULT_MEMOJI_ID);
    }
  }, []);

  function handleMemojiSelect(id: string) {
    setMemojiId(id);
    try {
      localStorage.setItem(STORAGE_KEY, id);
    } catch {
      // localStorage unavailable — selection still works in-memory
    }
  }

  const currentMemoji =
    memojiId !== null
      ? (MEMOJIS.find((m) => m.id === memojiId) ?? MEMOJIS[0])
      : null;

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
            {currentMemoji ? (
              <img
                src={currentMemoji.url}
                alt="Your memoji"
                width={66}
                height={66}
                className="h-full w-full rounded-full object-cover"
              />
            ) : (
              // Placeholder shown before mount (matches SSR — no hydration mismatch)
              <div className="flex h-full w-full items-center justify-center rounded-full bg-gradient-to-br from-primary/85 to-primary text-primary-foreground">
                <span className="text-2xl font-semibold tracking-tight">H</span>
              </div>
            )}
            {/* Picker trigger — overlays the avatar, only rendered client-side */}
            {memojiId !== null && (
              <MemojiPicker
                selectedId={memojiId}
                onSelect={handleMemojiSelect}
              />
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
                {greeting.word}, Hen <span aria-hidden>{greeting.emoji}</span>
              </>
            ) : (
              "Hello, Hen"
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

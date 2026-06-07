"use client";

import { useEffect, useState } from "react";
import { motion, useReducedMotion } from "framer-motion";
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

function TypewriterText({ text }: { text: string }) {
  const reduceMotion = useReducedMotion();
  const [count, setCount] = useState(0);

  useEffect(() => {
    if (reduceMotion) return;

    const id = window.setInterval(() => {
      setCount((current) => {
        const next = current + 1;
        if (next >= text.length) window.clearInterval(id);
        return next;
      });
    }, 22);

    return () => window.clearInterval(id);
  }, [reduceMotion, text]);

  if (reduceMotion) return <>{text}</>;

  const visible = text.slice(0, count);

  return (
    <>
      {visible}
      {visible.length < text.length && (
        <motion.span
          aria-hidden="true"
          animate={{ opacity: [0, 1, 0] }}
          transition={{ duration: 0.9, repeat: Infinity }}
          className="ml-0.5 inline-block h-4 w-px translate-y-0.5 bg-muted-foreground"
        />
      )}
    </>
  );
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

  const { name, memojiId, profileImageUrl, ready, setMemojiId } = useSettings();

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
  const avatarUrl = profileImageUrl ?? currentMemoji.url;

  const greeting = now ? greetingFor(now.getHours()) : null;
  const dayPercent = now
    ? Math.round(((now.getHours() * 60 + now.getMinutes()) / 1440) * 100)
    : null;

  // Ring geometry.
  const size = 64;
  const stroke = 4;
  const radius = (size - stroke) / 2;
  const circumference = 2 * Math.PI * radius;
  const dashOffset =
    dayPercent === null
      ? circumference
      : circumference * (1 - dayPercent / 100);

  return (
    <Card className="flex h-full flex-col rounded-3xl bg-card/85 animate-fade-in-up">
      <div className="flex flex-col items-center gap-4 px-5 py-4 text-center sm:flex-row sm:px-6 sm:text-left">
        {/* Avatar + progress ring */}
        <div
          className="relative shrink-0 transition-transform duration-200 hover:scale-105"
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
                src={avatarUrl}
                alt={`${name}'s avatar`}
                width={52}
                height={52}
                className="h-full w-full rounded-full object-cover"
              />
            ) : (
              // Placeholder shown before hydration (matches SSR — no mismatch)
              <div className="flex h-full w-full items-center justify-center rounded-full bg-gradient-to-br from-primary/85 to-primary text-primary-foreground">
                <span className="text-xl font-semibold tracking-tight">
                  {name.charAt(0).toUpperCase() || "H"}
                </span>
              </div>
            )}
            {/* Picker trigger — overlays the avatar, only after hydration */}
            {ready && (
              <MemojiPicker selectedId={memojiId} onSelect={setMemojiId} />
            )}
          </div>

        </div>

        <div className="min-w-0 flex-1">
          <div className="flex flex-col gap-2 sm:flex-row sm:items-end sm:justify-between">
            <h2 className="text-xl font-semibold tracking-tight text-foreground sm:text-2xl">
            {greeting ? (
              <>
                {greeting.word}, {name} <span aria-hidden>{greeting.emoji}</span>
              </>
            ) : (
              `Hello, ${name}`
            )}
            </h2>
            <span className="rounded-full border border-border bg-muted/40 px-2.5 py-1 text-xs font-medium text-muted-foreground">
              {dayPercent === null ? "—" : `${dayPercent}% through today`}
            </span>
          </div>

          <div className="mt-2">
            {isLoading ? (
              <Skeleton className="mx-auto h-4 w-3/4 sm:mx-0" />
            ) : data?.message ? (
              <p className="text-sm leading-6 text-muted-foreground">
                <TypewriterText key={data.message} text={data.message} />
              </p>
            ) : (
              <p className="text-sm leading-6 text-muted-foreground">
                <TypewriterText
                  key={error ? "fallback-error" : "fallback-default"}
                  text={
                    error
                      ? "Hope your day is off to a good start."
                      : "Here's to a focused day ahead."
                  }
                />
              </p>
            )}
          </div>
        </div>
      </div>
    </Card>
  );
}

"use client";

import { useEffect, useState } from "react";
import { motion, useReducedMotion } from "framer-motion";
import useSWR from "swr";

import { CloudAvatar } from "@/components/cloud-avatar";
import { Skeleton } from "@/components/ui/skeleton";
import { fetcher } from "@/lib/fetcher";
import type { GreetingResponse, SpotifyResponse, GithubResponse, IbkrResponse } from "@/lib/types";
import type { CloudState } from "@/lib/cloud-state";
import { getCloudGreeting } from "@/lib/cloud-greeting";
import { useSettings } from "@/components/settings-provider";

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
          className="ml-0.5 inline-block h-5 w-px translate-y-0.5 bg-muted-foreground"
        />
      )}
    </>
  );
}

function useWidgetContext() {
  const { data: spotify } = useSWR<SpotifyResponse>("/api/spotify", fetcher, {
    revalidateOnFocus: false,
  });
  const { data: github } = useSWR<GithubResponse>("/api/github", fetcher, {
    revalidateOnFocus: false,
  });
  const { data: ibkr } = useSWR<IbkrResponse>("/api/ibkr", fetcher, {
    revalidateOnFocus: false,
  });

  const todayStr = new Date().toISOString().slice(0, 10);
  const todayCommits = github?.contributions?.find((d) => d.date === todayStr)?.count ?? 0;

  const portfolioChange =
    ibkr?.summary.dayPnl != null && ibkr.summary.totalValue > 0
      ? (ibkr.summary.dayPnl / (ibkr.summary.totalValue - ibkr.summary.dayPnl)) * 100
      : undefined;

  const nowPlaying =
    spotify?.nowPlaying?.isPlaying
      ? `${spotify.nowPlaying.title} by ${spotify.nowPlaying.artist}`
      : undefined;

  return { commits: todayCommits, portfolioChange, nowPlaying };
}

export function HeroZone({ cloudState }: { cloudState: CloudState }) {
  const { commits, portfolioChange, nowPlaying } = useWidgetContext();

  const { data, isLoading, error } = useSWR<GreetingResponse>(
    ["/api/ai/greeting", commits, portfolioChange, nowPlaying, cloudState],
    () =>
      fetch("/api/ai/greeting", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          events: [],
          tasks: [],
          commits,
          portfolioChange,
          nowPlaying,
          mood: cloudState,
        }),
      }).then((r) => r.json()),
    { revalidateOnFocus: false }
  );

  const { name } = useSettings();
  const greeting = getCloudGreeting(cloudState, name);

  return (
    <div
      className="relative flex flex-col items-center justify-center text-center"
      style={{
        minHeight: "clamp(320px, 50vh, 600px)",
        WebkitAppRegion: "drag",
      } as React.CSSProperties}
    >
      <div
        className="flex flex-col items-center gap-6"
        style={{ WebkitAppRegion: "no-drag" } as React.CSSProperties}
      >
        <CloudAvatar state={cloudState} size="hero" />

        <div className="max-w-lg space-y-3">
          <h1 className="text-3xl font-bold tracking-tight text-foreground sm:text-4xl lg:text-5xl">
            {greeting.primary}
          </h1>

          <div className="min-h-[1.75rem]">
            {isLoading ? (
              <Skeleton className="mx-auto h-5 w-3/4" />
            ) : data?.message ? (
              <p className="text-base leading-relaxed text-muted-foreground sm:text-lg">
                <TypewriterText key={data.message} text={data.message} />
              </p>
            ) : (
              <p className="text-base leading-relaxed text-muted-foreground sm:text-lg">
                <TypewriterText
                  key={error ? "fallback-error" : "fallback-default"}
                  text={greeting.secondary}
                />
              </p>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

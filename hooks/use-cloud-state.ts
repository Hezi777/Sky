"use client";

import { useEffect, useState } from "react";
import useSWR from "swr";

import { fetcher } from "@/lib/fetcher";
import { getCloudState, type CloudState } from "@/lib/cloud-state";
import type { GithubResponse, IbkrResponse } from "@/lib/types";

export function useCloudState(): { state: CloudState; isLoading: boolean } {
  const [hour, setHour] = useState(() => new Date().getHours());

  useEffect(() => {
    const id = setInterval(() => setHour(new Date().getHours()), 5 * 60_000);
    return () => clearInterval(id);
  }, []);

  const { data: github } = useSWR<GithubResponse>("/api/github", fetcher, {
    refreshInterval: 300_000,
  });
  const { data: ibkr } = useSWR<IbkrResponse>("/api/ibkr", fetcher, {
    refreshInterval: 30_000,
  });

  const todayStr = new Date().toISOString().slice(0, 10);
  const todayCommits = github?.contributions?.find((d) => d.date === todayStr)?.count ?? 0;

  // IBKR: derive day change percent from dayPnl / (totalValue - dayPnl)
  const portfolioChangePercent =
    ibkr?.summary.dayPnl != null && ibkr.summary.totalValue > 0
      ? (ibkr.summary.dayPnl / (ibkr.summary.totalValue - ibkr.summary.dayPnl)) * 100
      : undefined;

  const isLoading = !github;

  const state = getCloudState({
    hour,
    githubCommits: todayCommits,
    ticktickCompleted: 0, // TickTick API doesn't expose completed count yet
    portfolioChangePercent,
    // sleepScore: not available — no health data source wired up
  });

  return { state, isLoading };
}

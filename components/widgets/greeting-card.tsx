"use client";

import { useEffect, useState } from "react";
import { motion, useReducedMotion } from "framer-motion";
import useSWR from "swr";

import { Card } from "@/components/ui/card";
import { CloudAvatar } from "@/components/cloud-avatar";
import { Skeleton } from "@/components/ui/skeleton";
import type { GreetingResponse } from "@/lib/types";
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
          className="ml-0.5 inline-block h-4 w-px translate-y-0.5 bg-muted-foreground"
        />
      )}
    </>
  );
}

export function GreetingCard({ cloudState }: { cloudState: CloudState }) {
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

  const { name } = useSettings();

  const [now, setNow] = useState<Date | null>(null);

  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setNow(new Date());
    const id = setInterval(() => setNow(new Date()), 60_000);
    return () => clearInterval(id);
  }, []);

  const greeting = getCloudGreeting(cloudState, name);
  const dayPercent = now
    ? Math.round(((now.getHours() * 60 + now.getMinutes()) / 1440) * 100)
    : null;

  return (
    <Card className="flex h-full flex-col rounded-3xl bg-card/85 animate-fade-in-up">
      <div className="flex flex-col items-center gap-4 px-5 py-4 text-center sm:flex-row sm:px-6 sm:text-left">
        <CloudAvatar state={cloudState} size="md" className="shrink-0" />

        <div className="min-w-0 flex-1">
          <div className="flex flex-col gap-2 sm:flex-row sm:items-end sm:justify-between">
            <h2 className="text-xl font-semibold tracking-tight text-foreground sm:text-2xl">
              {greeting.primary}
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
                  text={greeting.secondary}
                />
              </p>
            )}
          </div>
        </div>
      </div>
    </Card>
  );
}

"use client";

import { useEffect, useState } from "react";

import { ThemeToggle } from "@/components/theme-toggle";

function partOfDay(hour: number) {
  if (hour < 12) return "Good morning";
  if (hour < 18) return "Good afternoon";
  return "Good evening";
}

export function Header() {
  // null until mounted so server and first client render match (no hydration mismatch).
  const [now, setNow] = useState<Date | null>(null);

  useEffect(() => {
    // Set on mount (not during render) so SSR and first client render match.
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setNow(new Date());
    const id = setInterval(() => setNow(new Date()), 1000);
    return () => clearInterval(id);
  }, []);

  const greeting = now ? partOfDay(now.getHours()) : "Hello";

  return (
    <header className="flex items-center justify-between gap-4 border-b border-border px-4 py-4 sm:px-6">
      <div>
        <h1 className="text-xl font-semibold tracking-tight">{greeting}, Hen</h1>
        <p className="text-sm text-muted-foreground">
          {now
            ? now.toLocaleDateString(undefined, {
                weekday: "long",
                month: "long",
                day: "numeric",
              })
            : " "}
        </p>
      </div>

      <div className="flex items-center gap-3">
        <span className="hidden font-mono text-sm tabular-nums text-muted-foreground sm:inline">
          {now
            ? now.toLocaleTimeString(undefined, {
                hour: "2-digit",
                minute: "2-digit",
              })
            : ""}
        </span>
        <ThemeToggle />
      </div>
    </header>
  );
}

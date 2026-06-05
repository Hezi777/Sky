"use client";

import useSWR from "swr";
import { SiNotion } from "react-icons/si";
import { AlertCircle, ArrowUpRight, Sparkles } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Separator } from "@/components/ui/separator";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Skeleton } from "@/components/ui/skeleton";
import { fetcher } from "@/lib/fetcher";
import type { NotionNextTask } from "@/lib/types";

// Shared accent language with ActiveProjects: stage → token-based color
// that reads well in both light and dark mode.
function stageStyle(stage: string): { badge: string; accent: string; ring: string } {
  const key = stage.trim().toLowerCase();
  if (key.includes("progress")) {
    return {
      badge:
        "border-transparent bg-blue-500/15 text-blue-600 dark:bg-blue-400/15 dark:text-blue-300",
      accent: "bg-blue-500 dark:bg-blue-400",
      ring: "from-blue-500/10",
    };
  }
  if (key.includes("finish") || key.includes("review")) {
    return {
      badge:
        "border-transparent bg-amber-500/15 text-amber-600 dark:bg-amber-400/15 dark:text-amber-300",
      accent: "bg-amber-500 dark:bg-amber-400",
      ring: "from-amber-500/10",
    };
  }
  if (key.includes("done") || key.includes("complete") || key.includes("ship")) {
    return {
      badge:
        "border-transparent bg-emerald-500/15 text-emerald-600 dark:bg-emerald-400/15 dark:text-emerald-300",
      accent: "bg-emerald-500 dark:bg-emerald-400",
      ring: "from-emerald-500/10",
    };
  }
  if (key.includes("plan") || key.includes("backlog") || key.includes("idea")) {
    return {
      badge:
        "border-transparent bg-violet-500/15 text-violet-600 dark:bg-violet-400/15 dark:text-violet-300",
      accent: "bg-violet-500 dark:bg-violet-400",
      ring: "from-violet-500/10",
    };
  }
  return {
    badge: "border-transparent bg-muted text-muted-foreground",
    accent: "bg-muted-foreground/50",
    ring: "from-primary/5",
  };
}

function initials(name: string): string {
  const words = name.trim().split(/\s+/).filter(Boolean);
  if (words.length === 0) return "?";
  if (words.length === 1) return words[0].slice(0, 2).toUpperCase();
  return (words[0][0] + words[words.length - 1][0]).toUpperCase();
}

function splitStack(stack: string): string[] {
  return stack
    .split(/[,/·•]| - /)
    .map((s) => s.trim())
    .filter(Boolean)
    .slice(0, 4);
}

export function NextTask() {
  const { data, error, isLoading } = useSWR<NotionNextTask | null>(
    "/api/notion/nexttask",
    fetcher
  );

  const style = data ? stageStyle(data.stage) : null;
  const stack = data?.stack ? splitStack(data.stack) : [];

  return (
    <Card className="relative flex h-full flex-col overflow-hidden rounded-2xl">
      {/* soft stage-tinted spotlight glow */}
      {style && (
        <div
          aria-hidden
          className={`pointer-events-none absolute -top-16 -right-16 size-44 rounded-full bg-radial ${style.ring} to-transparent blur-2xl`}
        />
      )}

      <CardHeader className="relative flex flex-row items-center gap-2 pb-3">
        <SiNotion className="h-4 w-4 shrink-0 text-muted-foreground" />
        <CardTitle className="text-sm font-semibold">Next Task</CardTitle>
        <span className="ml-auto inline-flex items-center gap-1 text-[10px] font-medium tracking-wide text-muted-foreground uppercase">
          <Sparkles className="size-3" /> Focus
        </span>
      </CardHeader>

      <CardContent className="relative flex flex-1 flex-col">
        {isLoading && (
          <div className="space-y-3">
            <Skeleton className="h-7 w-5/6" />
            <Skeleton className="h-7 w-2/3" />
            <Skeleton className="h-4 w-1/2" />
            <Skeleton className="h-5 w-1/3" />
          </div>
        )}

        {error && (
          <div className="flex items-center gap-2 text-sm text-destructive">
            <AlertCircle className="h-4 w-4 shrink-0" />
            <span>{error.message ?? "Failed to load next task"}</span>
          </div>
        )}

        {!isLoading && !error && data === null && (
          <div className="flex flex-1 flex-col items-center justify-center gap-2 py-6 text-center">
            <div className="flex size-11 items-center justify-center rounded-full bg-muted">
              <Sparkles className="size-5 text-muted-foreground" />
            </div>
            <p className="text-sm font-medium text-foreground">
              Nothing in progress
            </p>
            <p className="text-xs text-muted-foreground">
              You&apos;re all caught up — pick your next move.
            </p>
          </div>
        )}

        {data && style && (
          <div className="flex flex-1 flex-col">
            {/* Hero: the next action */}
            <div className="flex items-start gap-2.5">
              <span
                className={`mt-2 size-2 shrink-0 rounded-full ${style.accent}`}
              />
              {data.nextAction ? (
                <p className="text-xl leading-tight font-semibold tracking-tight text-balance text-foreground">
                  {data.nextAction}
                </p>
              ) : (
                <p className="text-xl leading-tight font-semibold tracking-tight text-muted-foreground">
                  No next action set
                </p>
              )}
            </div>

            {/* Project identity */}
            <div className="mt-4 flex items-center gap-2.5">
              <Avatar size="sm">
                <AvatarFallback className="bg-primary/10 text-[10px] font-semibold text-primary">
                  {initials(data.name)}
                </AvatarFallback>
              </Avatar>
              <span className="truncate text-sm font-medium text-muted-foreground">
                {data.name}
              </span>
            </div>

            {/* Badges */}
            <div className="mt-3 flex flex-wrap items-center gap-1.5">
              {data.stage && (
                <Badge className={`text-[10px] ${style.badge}`}>
                  {data.stage}
                </Badge>
              )}
              {data.type && (
                <Badge variant="outline" className="text-[10px]">
                  {data.type}
                </Badge>
              )}
            </div>

            {/* Stack chips */}
            {stack.length > 0 && (
              <div className="mt-3 flex flex-wrap gap-1">
                {stack.map((s) => (
                  <span
                    key={s}
                    className="rounded-md bg-muted px-1.5 py-0.5 text-[10px] font-medium text-muted-foreground"
                  >
                    {s}
                  </span>
                ))}
              </div>
            )}

            <Separator className="mt-auto opacity-60" />
            <a
              href={data.url || "https://notion.so"}
              target="_blank"
              rel="noopener noreferrer"
              className="group/open flex items-center justify-between pt-3 text-xs font-medium text-muted-foreground transition-colors hover:text-foreground"
            >
              Open in Notion
              <ArrowUpRight className="size-3.5 transition-transform group-hover/open:translate-x-0.5 group-hover/open:-translate-y-0.5" />
            </a>
          </div>
        )}
      </CardContent>
    </Card>
  );
}

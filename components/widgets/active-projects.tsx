"use client";

import useSWR from "swr";
import { SiNotion } from "react-icons/si";
import { AlertCircle, ArrowUpRight } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Separator } from "@/components/ui/separator";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Skeleton } from "@/components/ui/skeleton";
import { fetcher } from "@/lib/fetcher";
import type { NotionProject } from "@/lib/types";

// Shared accent language between ActiveProjects and NextTask.
// Maps a project stage to a token-based color that reads well in light + dark.
function stageStyle(stage: string): { badge: string; accent: string } {
  const key = stage.trim().toLowerCase();
  if (key.includes("progress")) {
    return {
      badge:
        "border-transparent bg-blue-500/15 text-blue-600 dark:bg-blue-400/15 dark:text-blue-300",
      accent: "bg-blue-500 dark:bg-blue-400",
    };
  }
  if (key.includes("finish") || key.includes("review")) {
    return {
      badge:
        "border-transparent bg-amber-500/15 text-amber-600 dark:bg-amber-400/15 dark:text-amber-300",
      accent: "bg-amber-500 dark:bg-amber-400",
    };
  }
  if (key.includes("done") || key.includes("complete") || key.includes("ship")) {
    return {
      badge:
        "border-transparent bg-emerald-500/15 text-emerald-600 dark:bg-emerald-400/15 dark:text-emerald-300",
      accent: "bg-emerald-500 dark:bg-emerald-400",
    };
  }
  if (key.includes("plan") || key.includes("backlog") || key.includes("idea")) {
    return {
      badge:
        "border-transparent bg-violet-500/15 text-violet-600 dark:bg-violet-400/15 dark:text-violet-300",
      accent: "bg-violet-500 dark:bg-violet-400",
    };
  }
  return {
    badge:
      "border-transparent bg-muted text-muted-foreground",
    accent: "bg-muted-foreground/50",
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

function ProjectSkeleton() {
  return (
    <div className="flex items-start gap-3 py-1">
      <Skeleton className="size-9 shrink-0 rounded-full" />
      <div className="flex-1 space-y-2">
        <Skeleton className="h-4 w-3/4" />
        <Skeleton className="h-3 w-1/2" />
        <Skeleton className="h-3 w-2/3" />
      </div>
    </div>
  );
}

function ProjectRow({ project }: { project: NotionProject }) {
  const { badge, accent } = stageStyle(project.stage);
  const stack = project.stack ? splitStack(project.stack) : [];

  return (
    <a
      href={project.url || "https://notion.so"}
      target="_blank"
      rel="noopener noreferrer"
      className="group/row -mx-2 flex items-start gap-3 rounded-xl px-2 py-2 transition-colors hover:bg-muted/60"
    >
      <Avatar size="default" className="mt-0.5">
        <AvatarFallback className="bg-primary/10 text-xs font-semibold text-primary">
          {initials(project.name)}
        </AvatarFallback>
      </Avatar>

      <div className="min-w-0 flex-1 space-y-1.5">
        <div className="flex items-center gap-2">
          <span className={`size-1.5 shrink-0 rounded-full ${accent}`} />
          <p className="truncate text-sm font-semibold leading-snug text-foreground">
            {project.name}
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-1.5">
          {project.stage && (
            <Badge className={`text-[10px] ${badge}`}>{project.stage}</Badge>
          )}
          {project.type && (
            <Badge variant="outline" className="text-[10px]">
              {project.type}
            </Badge>
          )}
        </div>

        {stack.length > 0 && (
          <div className="flex flex-wrap gap-1">
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

        {project.nextAction && (
          <p className="truncate text-xs text-muted-foreground">
            <span className="text-foreground/60">→</span> {project.nextAction}
          </p>
        )}
      </div>
    </a>
  );
}

export function ActiveProjects() {
  const { data, error, isLoading } = useSWR<NotionProject[]>(
    "/api/notion/projects",
    fetcher
  );

  return (
    <Card className="flex h-full flex-col rounded-2xl">
      <CardHeader className="flex flex-row items-center gap-2 pb-3">
        <SiNotion className="h-4 w-4 shrink-0 text-muted-foreground" />
        <CardTitle className="text-sm font-semibold">Active Projects</CardTitle>
      </CardHeader>

      <CardContent className="flex flex-1 flex-col">
        {isLoading && (
          <div className="space-y-2">
            <ProjectSkeleton />
            <ProjectSkeleton />
            <ProjectSkeleton />
          </div>
        )}

        {error && (
          <div className="flex items-center gap-2 text-sm text-destructive">
            <AlertCircle className="h-4 w-4 shrink-0" />
            <span>{error.message ?? "Failed to load projects"}</span>
          </div>
        )}

        {data && data.length === 0 && (
          <p className="text-sm text-muted-foreground">No active projects.</p>
        )}

        {data && data.length > 0 && (
          <div className="-my-1 flex flex-col">
            {data.slice(0, 4).map((project, i) => (
              <div key={project.id}>
                {i > 0 && <Separator className="opacity-60" />}
                <ProjectRow project={project} />
              </div>
            ))}
          </div>
        )}

        <Separator className="mt-auto opacity-60" />
        <a
          href="https://notion.so"
          target="_blank"
          rel="noopener noreferrer"
          className="group/all flex items-center justify-between pt-3 text-xs font-medium text-muted-foreground transition-colors hover:text-foreground"
        >
          See all in Notion
          <ArrowUpRight className="size-3.5 transition-transform group-hover/all:translate-x-0.5 group-hover/all:-translate-y-0.5" />
        </a>
      </CardContent>
    </Card>
  );
}

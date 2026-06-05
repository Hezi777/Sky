"use client";

import useSWR from "swr";
import { ListChecks } from "lucide-react";

import { BrandLogo } from "@/components/brand-logo";
import { fetcher } from "@/lib/fetcher";
import type { TickTickTask, TickTickPriority } from "@/lib/types";
import {
  Card,
  CardHeader,
  CardTitle,
  CardContent,
} from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";

// ---------------------------------------------------------------------------
// Priority badge
// ---------------------------------------------------------------------------

const PRIORITY_LABEL: Record<TickTickPriority, string> = {
  none: "None",
  low: "Low",
  medium: "Medium",
  high: "High",
};

// We can't use arbitrary Tailwind classes that don't exist in the stylesheet,
// so we use a className string that relies on known Tailwind utility classes.
// shadcn Badge doesn't expose a color prop, so we override via className.
function PriorityBadge({ priority }: { priority: TickTickPriority }) {
  let className = "";
  switch (priority) {
    case "high":
      className =
        "bg-red-100 text-red-700 border-red-200 dark:bg-red-900/30 dark:text-red-400 dark:border-red-800";
      break;
    case "medium":
      className =
        "bg-amber-100 text-amber-700 border-amber-200 dark:bg-amber-900/30 dark:text-amber-400 dark:border-amber-800";
      break;
    case "low":
      className =
        "bg-blue-100 text-blue-700 border-blue-200 dark:bg-blue-900/30 dark:text-blue-400 dark:border-blue-800";
      break;
    default:
      className =
        "bg-muted text-muted-foreground border-border";
  }

  return (
    <Badge variant="outline" className={className}>
      {PRIORITY_LABEL[priority]}
    </Badge>
  );
}

// ---------------------------------------------------------------------------
// Skeleton loader
// ---------------------------------------------------------------------------

function TickTickSkeleton() {
  return (
    <Card className="flex h-full flex-col rounded-2xl">
      <CardHeader>
        <div className="flex items-center gap-2">
          <Skeleton className="size-4 rounded" />
          <Skeleton className="h-4 w-28 rounded" />
        </div>
      </CardHeader>
      <CardContent className="flex flex-col gap-3">
        {[1, 2, 3].map((i) => (
          <div key={i} className="flex flex-col gap-1.5">
            <Skeleton className="h-4 w-full rounded" />
            <Skeleton className="h-3 w-20 rounded" />
          </div>
        ))}
      </CardContent>
    </Card>
  );
}

// ---------------------------------------------------------------------------
// Task row
// ---------------------------------------------------------------------------

function TaskRow({ task }: { task: TickTickTask }) {
  const dueTime = task.dueDate
    ? new Date(task.dueDate).toLocaleTimeString(undefined, {
        hour: "2-digit",
        minute: "2-digit",
      })
    : null;

  return (
    <li className="flex flex-col gap-1 border-b border-border pb-3 last:border-0 last:pb-0">
      {/* Title row */}
      <div className="flex items-start justify-between gap-2">
        <span className="text-sm font-medium leading-snug">{task.title}</span>
        <PriorityBadge priority={task.priority} />
      </div>

      {/* Meta row */}
      {(dueTime || task.tags.length > 0 || task.subtaskCount > 0) && (
        <div className="flex flex-wrap items-center gap-1.5 text-xs text-muted-foreground">
          {dueTime && (
            <span className="tabular-nums">{dueTime}</span>
          )}

          {task.subtaskCount > 0 && (
            <span className="text-xs text-muted-foreground">
              {task.subtaskCount} subtask{task.subtaskCount !== 1 ? "s" : ""}
            </span>
          )}

          {task.tags.map((tag) => (
            <span
              key={tag}
              className="rounded-full bg-muted px-2 py-0.5 text-xs text-muted-foreground"
            >
              {tag}
            </span>
          ))}
        </div>
      )}
    </li>
  );
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

export function TickTickWidget() {
  const { data, error, isLoading } = useSWR<TickTickTask[]>(
    "/api/ticktick",
    fetcher<TickTickTask[]>,
  );

  if (isLoading) return <TickTickSkeleton />;

  const hasError = error != null || (data as unknown as { error?: string })?.error != null;
  const errorMessage =
    error?.message ??
    (data as unknown as { error?: string })?.error ??
    "Could not load tasks";

  return (
    <Card className="flex h-full flex-col rounded-2xl">
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <BrandLogo name="ticktick" className="size-4 shrink-0" />
          Today&apos;s Tasks
        </CardTitle>
      </CardHeader>

      <CardContent className="min-h-0 flex-1 overflow-y-auto">
        {hasError ? (
          <div className="flex items-center gap-2 text-sm text-muted-foreground">
            <ListChecks className="size-4 shrink-0" aria-hidden />
            <span>{String(errorMessage)}</span>
          </div>
        ) : !data || data.length === 0 ? (
          <p className="text-sm text-muted-foreground">Nothing due today</p>
        ) : (
          <ul className="flex flex-col gap-3">
            {data.map((task) => (
              <TaskRow key={task.id} task={task} />
            ))}
          </ul>
        )}
      </CardContent>
    </Card>
  );
}

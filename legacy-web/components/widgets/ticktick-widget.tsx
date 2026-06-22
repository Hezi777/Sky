"use client";

import { useState } from "react";
import { AnimatePresence, motion } from "framer-motion";
import useSWR from "swr";
import { Cell, Pie, PieChart } from "recharts";
import { Clock3, ListChecks, ListTodo, RotateCcw, Tag } from "lucide-react";
import { toast } from "sonner";

import { BrandLogo } from "@/components/brand-logo";
import { fetcher } from "@/lib/fetcher";
import type { TickTickTask, TickTickPriority } from "@/lib/types";
import {
  Card,
  CardHeader,
  CardTitle,
  CardContent,
} from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";

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

const PRIORITY_CHECKBOX: Record<TickTickPriority, string> = {
  high: "border-red-500 text-red-500 hover:bg-red-500/10",
  medium: "border-amber-500 text-amber-500 hover:bg-amber-500/10",
  low: "border-blue-400 text-blue-400 hover:bg-blue-400/10",
  none: "border-border text-muted-foreground hover:bg-muted",
};

function TaskMetadata({ task, dueTime }: { task: TickTickTask; dueTime: string | null }) {
  if (!dueTime && task.tags.length === 0 && task.subtaskCount === 0) return null;

  return (
    <div className="ml-auto flex shrink-0 items-center gap-2 pl-3 text-xs text-muted-foreground">
      {task.subtaskCount > 0 && (
        <span
          className="inline-flex items-center gap-1"
          title={`${task.subtaskCount} subtasks`}
        >
          <ListTodo className="size-3.5" />
          <span className="tabular-nums">{task.subtaskCount}</span>
        </span>
      )}
      {task.tags.length > 0 && (
        <span
          className="inline-flex items-center gap-1"
          title={task.tags.join(", ")}
        >
          <Tag className="size-3.5" />
          <span className="max-w-20 truncate">{task.tags[0]}</span>
        </span>
      )}
      {dueTime && (
        <span className="inline-flex items-center gap-1 text-primary/80">
          <Clock3 className="size-3.5" />
          <span className="tabular-nums">{dueTime}</span>
        </span>
      )}
    </div>
  );
}

function TaskRow({
  task,
  onComplete,
}: {
  task: TickTickTask;
  onComplete: (task: TickTickTask) => void;
}) {
  const dueTime = task.dueDate
    ? new Date(task.dueDate).toLocaleTimeString(undefined, {
        hour: "2-digit",
        minute: "2-digit",
      })
    : null;

  return (
    <motion.li
      layout
      initial={{ opacity: 0, y: 6 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{
        opacity: 0,
        x: 18,
        height: 0,
        paddingTop: 0,
        paddingBottom: 0,
        marginTop: 0,
        marginBottom: 0,
      }}
      transition={{ duration: 0.22, ease: [0.22, 1, 0.36, 1] }}
      className="flex min-h-10 items-center gap-2.5 overflow-hidden border-b border-border py-2.5 first:pt-0 last:border-0 last:pb-0"
    >
      <button
        type="button"
        aria-label={`Complete: ${task.title}`}
        onClick={() => onComplete(task)}
        className={`h-4 w-4 shrink-0 rounded-[4px] border-2 bg-card transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring/50 ${PRIORITY_CHECKBOX[task.priority]}`}
      />

      <div className="flex min-w-0 flex-1 items-center gap-2">
        <span
          dir="ltr"
          className="min-w-0 flex-1 truncate text-left text-sm font-medium leading-snug [unicode-bidi:plaintext]"
        >
          {task.title}
        </span>
        <TaskMetadata task={task} dueTime={dueTime} />
      </div>
    </motion.li>
  );
}

// ---------------------------------------------------------------------------
// Progress ring
// ---------------------------------------------------------------------------

function TaskProgressRing({ completed, total }: { completed: number; total: number }) {
  if (total === 0) return null;
  const ratio = completed / total;
  const color = ratio >= 0.7 ? "#22c55e" : ratio >= 0.4 ? "#f59e0b" : "#ef4444";
  const data = [
    { value: completed },
    { value: Math.max(0, total - completed) },
  ];

  return (
    <div className="relative flex items-center justify-center" style={{ width: 36, height: 36 }}>
      <PieChart width={36} height={36}>
        <Pie
          data={data}
          cx="50%"
          cy="50%"
          innerRadius={12}
          outerRadius={16}
          startAngle={90}
          endAngle={-270}
          dataKey="value"
          stroke="none"
          cornerRadius={8}
        >
          <Cell fill={color} />
          <Cell fill="var(--muted)" />
        </Pie>
      </PieChart>
      <span className="absolute text-[9px] font-bold tabular-nums text-foreground">
        {completed}/{total}
      </span>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

async function completeTask(taskId: string, projectId: string) {
  const res = await fetch("/api/ticktick/complete", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ taskId, projectId }),
  });
  if (!res.ok) throw new Error("Failed to complete task");
}

async function uncompleteTask(taskId: string, projectId: string) {
  const res = await fetch("/api/ticktick/complete", {
    method: "DELETE",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ taskId, projectId }),
  });
  if (!res.ok) throw new Error("Failed to revert task");
}

export function TickTickWidget() {
  const { data, error, isLoading, mutate } = useSWR<TickTickTask[]>(
    "/api/ticktick",
    fetcher<TickTickTask[]>,
    { refreshInterval: 15_000 },
  );

  const [hidden, setHidden] = useState<Set<string>>(new Set());

  if (isLoading) return <TickTickSkeleton />;

  const hasError = error != null || (data as unknown as { error?: string })?.error != null;
  const errorMessage =
    error?.message ??
    (data as unknown as { error?: string })?.error ??
    "Could not load tasks";

  const visibleTasks = (data ?? []).filter((t) => !hidden.has(t.id));

  function handleComplete(task: TickTickTask) {
    // Optimistically hide
    setHidden((prev) => new Set([...prev, task.id]));

    // Fire API
    completeTask(task.id, task.projectId).catch(() => {
      // Revert on error
      setHidden((prev) => {
        const next = new Set(prev);
        next.delete(task.id);
        return next;
      });
      toast.error("Could not complete task");
    });

    // Toast with undo
    toast("Task completed", {
      duration: 5000,
      action: {
        label: (
          <span className="inline-flex items-center gap-1.5">
            <RotateCcw className="h-3.5 w-3.5" />
            Undo
          </span>
        ),
        onClick: () => {
          setHidden((prev) => {
            const next = new Set(prev);
            next.delete(task.id);
            return next;
          });
          uncompleteTask(task.id, task.projectId).catch(() => {
            toast.error("Could not revert task");
          });
          mutate();
        },
      },
    });
  }

  return (
    <Card className="flex h-full flex-col rounded-2xl">
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <BrandLogo name="ticktick" className="size-4 shrink-0" />
          Today&apos;s Tasks
          <span className="ml-auto">
            <TaskProgressRing
              completed={hidden.size}
              total={(data ?? []).length}
            />
          </span>
        </CardTitle>
      </CardHeader>

      <CardContent className="min-h-0 flex-1 overflow-y-auto">
        {hasError ? (
          <div className="flex items-center gap-2 text-sm text-muted-foreground">
            <ListChecks className="size-4 shrink-0" aria-hidden />
            <span>{String(errorMessage)}</span>
          </div>
        ) : visibleTasks.length === 0 ? (
          <p className="text-sm text-muted-foreground">Nothing due today</p>
        ) : (
          <motion.ul layout className="flex flex-col">
            <AnimatePresence initial={false}>
              {visibleTasks.map((task) => (
                <TaskRow key={task.id} task={task} onComplete={handleComplete} />
              ))}
            </AnimatePresence>
          </motion.ul>
        )}
      </CardContent>
    </Card>
  );
}

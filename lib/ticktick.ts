import type { TickTickTask, TickTickPriority } from "@/lib/types";

// ---------------------------------------------------------------------------
// Auth
// ---------------------------------------------------------------------------

// TickTick's OAuth does NOT issue refresh tokens — its authorization_code grant
// returns a single long-lived access token (~6 months). So we store that access
// token directly (TICKTICK_ACCESS_TOKEN) and use it as the Bearer credential.
// Re-run scripts/get-ticktick-token.mjs to mint a fresh one when it expires.
async function getAccessToken(): Promise<string> {
  const token = process.env.TICKTICK_ACCESS_TOKEN;
  if (!token || token === "undefined") {
    throw new Error(
      "Missing TICKTICK_ACCESS_TOKEN — run `node scripts/get-ticktick-token.mjs`",
    );
  }
  return token;
}

// ---------------------------------------------------------------------------
// Parsing helpers
// ---------------------------------------------------------------------------

// TickTick priority numbers → our union type
function mapPriority(p: unknown): TickTickPriority {
  switch (p) {
    case 1:
      return "low";
    case 3:
      return "medium";
    case 5:
      return "high";
    default:
      return "none";
  }
}

// Returns today's date string in local time as "YYYY-MM-DD"
function todayLocal(): string {
  const d = new Date();
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  return `${y}-${m}-${day}`;
}

// Given any ISO-ish date string from TickTick, return the YYYY-MM-DD portion
// in local time (TickTick sends UTC-based strings like "2025-06-05T00:00:00+0000"
// or just "2025-06-05T00:00:00.000+0000"). We parse via Date() so the host's
// local TZ is applied.
function dateLocalStr(raw: string): string {
  const d = new Date(raw);
  if (isNaN(d.getTime())) return "";
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  return `${y}-${m}-${day}`;
}

// Returns true when the raw date string has a non-midnight time component
// (i.e. the task has a specific time, not just an all-day date).
function hasTime(raw: string): boolean {
  const d = new Date(raw);
  if (isNaN(d.getTime())) return false;
  return d.getHours() !== 0 || d.getMinutes() !== 0 || d.getSeconds() !== 0;
}

// ---------------------------------------------------------------------------
// Priority sort helpers
// ---------------------------------------------------------------------------

const PRIORITY_ORDER: Record<TickTickPriority, number> = {
  high: 3,
  medium: 2,
  low: 1,
  none: 0,
};

// ---------------------------------------------------------------------------
// Official Open API host / paths  — change only here if TickTick updates them
// ---------------------------------------------------------------------------

const OPEN_API_BASE = "https://api.ticktick.com/open/v1";
const PROJECTS_PATH = "/project";
const PROJECT_DATA_PATH = (projectId: string) => `/project/${projectId}/data`;

// ---------------------------------------------------------------------------
// Raw Open-API shapes
// We type these loosely; the API surface can change and we want to be defensive.
// ---------------------------------------------------------------------------

interface RawOpenProject {
  id?: string;
  name?: string;
  [key: string]: unknown;
}

interface RawOpenTask {
  id?: string;
  title?: string;
  priority?: number;
  status?: number;       // 0 = incomplete, 2 = completed
  dueDate?: string;
  startDate?: string;
  tags?: string[];
  items?: unknown[];     // subtasks
  [key: string]: unknown;
}

interface RawProjectData {
  tasks?: RawOpenTask[];
  [key: string]: unknown;
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

export { getAccessToken };

export async function getTodayTasks(): Promise<TickTickTask[]> {
  const token = await getAccessToken();

  const authHeaders = {
    Authorization: `Bearer ${token}`,
  };

  // Step 1: list all projects
  const projectsRes = await fetch(`${OPEN_API_BASE}${PROJECTS_PATH}`, {
    headers: authHeaders,
    cache: "no-store",
  });

  if (!projectsRes.ok) {
    const text = await projectsRes.text().catch(() => projectsRes.statusText);
    throw new Error(`TickTick projects fetch failed (${projectsRes.status}): ${text}`);
  }

  let projects: RawOpenProject[];
  try {
    projects = (await projectsRes.json()) as RawOpenProject[];
  } catch {
    throw new Error("TickTick projects response was not valid JSON");
  }

  if (!Array.isArray(projects) || projects.length === 0) {
    return [];
  }

  // Step 2: fetch each project's tasks in parallel; tolerate per-project failures
  const projectDataResults = await Promise.allSettled(
    projects.map(async (project): Promise<RawOpenTask[]> => {
      const id = project?.id;
      if (typeof id !== "string" || id === "") return [];

      const res = await fetch(`${OPEN_API_BASE}${PROJECT_DATA_PATH(id)}`, {
        headers: authHeaders,
        cache: "no-store",
      });

      if (!res.ok) {
        // Non-fatal: skip this project
        return [];
      }

      let data: RawProjectData;
      try {
        data = (await res.json()) as RawProjectData;
      } catch {
        return [];
      }

      return Array.isArray(data?.tasks) ? data.tasks : [];
    })
  );

  // Flatten all tasks, discarding any rejected promises
  const allRawTasks: RawOpenTask[] = projectDataResults.flatMap((result) =>
    result.status === "fulfilled" ? result.value : []
  );

  const today = todayLocal();

  const filtered: TickTickTask[] = allRawTasks
    .filter((t): t is RawOpenTask & { id: string; title: string } => {
      if (!t || typeof t.id !== "string" || typeof t.title !== "string") return false;
      // Incomplete only (status 0; completed is 2)
      if (t.status !== 0) return false;
      // Due today OR starting today (local time)
      const dueDateStr = typeof t.dueDate === "string" ? dateLocalStr(t.dueDate) : "";
      const startDateStr = typeof t.startDate === "string" ? dateLocalStr(t.startDate) : "";
      return dueDateStr === today || startDateStr === today;
    })
    .map((t) => {
      // Prefer dueDate for display; fall back to startDate
      const rawDate = t.dueDate ?? t.startDate ?? null;
      const dueDate =
        rawDate && typeof rawDate === "string" && hasTime(rawDate)
          ? new Date(rawDate).toISOString()
          : null;

      return {
        id: t.id,
        title: t.title,
        priority: mapPriority(t.priority),
        dueDate,
        tags: Array.isArray(t.tags)
          ? t.tags.filter((tag): tag is string => typeof tag === "string")
          : [],
        subtaskCount: Array.isArray(t.items) ? t.items.length : 0,
      };
    });

  // Sort: priority desc, then dueDate asc (nulls last)
  filtered.sort((a, b) => {
    const pDiff = PRIORITY_ORDER[b.priority] - PRIORITY_ORDER[a.priority];
    if (pDiff !== 0) return pDiff;
    if (a.dueDate === null && b.dueDate === null) return 0;
    if (a.dueDate === null) return 1;
    if (b.dueDate === null) return -1;
    return a.dueDate.localeCompare(b.dueDate);
  });

  return filtered;
}

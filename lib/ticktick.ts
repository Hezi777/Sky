import type { TickTickTask, TickTickPriority } from "@/lib/types";

// ---------------------------------------------------------------------------
// Parsing helpers
// ---------------------------------------------------------------------------

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

function todayLocal(): string {
  const d = new Date();
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  return `${y}-${m}-${day}`;
}

function dateLocalStr(raw: string): string {
  const d = new Date(raw);
  if (isNaN(d.getTime())) return "";
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  return `${y}-${m}-${day}`;
}

function hasTime(raw: string): boolean {
  const d = new Date(raw);
  if (isNaN(d.getTime())) return false;
  return d.getHours() !== 0 || d.getMinutes() !== 0 || d.getSeconds() !== 0;
}

const PRIORITY_ORDER: Record<TickTickPriority, number> = {
  high: 3,
  medium: 2,
  low: 1,
  none: 0,
};

// ---------------------------------------------------------------------------
// Shared task shape (used by both v1 and v2 paths)
// ---------------------------------------------------------------------------

interface RawTask {
  id?: string;
  title?: string;
  priority?: number;
  status?: number;
  dueDate?: string;
  startDate?: string;
  tags?: string[];
  items?: unknown[];
  [key: string]: unknown;
}

function rawToTask(t: RawTask & { id: string; title: string }, projectId = ""): TickTickTask {
  const rawDate = t.dueDate ?? t.startDate ?? null;
  const dueDate =
    rawDate && typeof rawDate === "string" && hasTime(rawDate)
      ? new Date(rawDate).toISOString()
      : null;
  return {
    id: t.id,
    projectId: typeof t.projectId === "string" ? t.projectId : projectId,
    title: t.title,
    priority: mapPriority(t.priority),
    dueDate,
    tags: Array.isArray(t.tags)
      ? t.tags.filter((tag): tag is string => typeof tag === "string")
      : [],
    subtaskCount: Array.isArray(t.items) ? t.items.length : 0,
  };
}

function filterAndSort(allRawTasks: RawTask[]): TickTickTask[] {
  const today = todayLocal();

  const tasks: TickTickTask[] = allRawTasks
    .filter((t): t is RawTask & { id: string; title: string } => {
      if (!t || typeof t.id !== "string" || typeof t.title !== "string") return false;
      if (t.status !== 0) return false;
      const dueDateStr = typeof t.dueDate === "string" ? dateLocalStr(t.dueDate) : "";
      const startDateStr = typeof t.startDate === "string" ? dateLocalStr(t.startDate) : "";
      return dueDateStr === today || startDateStr === today;
    })
    .map((t) => rawToTask(t));

  tasks.sort((a, b) => {
    const pDiff = PRIORITY_ORDER[b.priority] - PRIORITY_ORDER[a.priority];
    if (pDiff !== 0) return pDiff;
    if (a.dueDate === null && b.dueDate === null) return 0;
    if (a.dueDate === null) return 1;
    if (b.dueDate === null) return -1;
    return a.dueDate.localeCompare(b.dueDate);
  });

  return tasks;
}


// ---------------------------------------------------------------------------
// Official TickTick MCP - includes Inbox and Today smart list
// ---------------------------------------------------------------------------

const MCP_URL = "https://mcp.ticktick.com";
const MCP_PROTOCOL_VERSION = "2025-06-18";

interface McpTask {
  id?: string;
  project_id?: string;
  title?: string;
  priority?: number;
  status?: number;
  due_date?: string;
  start_date?: string;
  is_all_day?: boolean;
  tags?: string[];
  items?: unknown[];
}

async function callTickTickMcpTool<T>(
  name: string,
  args: Record<string, unknown>,
): Promise<T> {
  const token = process.env.TICKTICK_MCP_TOKEN;
  if (!token) throw new Error("Missing TICKTICK_MCP_TOKEN");

  const res = await fetch(MCP_URL, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
      Accept: "application/json, text/event-stream",
      "MCP-Protocol-Version": MCP_PROTOCOL_VERSION,
    },
    body: JSON.stringify({
      jsonrpc: "2.0",
      id: `${name}-${Date.now()}`,
      method: "tools/call",
      params: { name, arguments: args },
    }),
    cache: "no-store",
  });

  const text = await res.text();
  if (!res.ok) throw new Error(`TickTick MCP ${name} failed (${res.status}): ${text}`);

  const payload = JSON.parse(text) as {
    result?: {
      isError?: boolean;
      content?: Array<{ text?: string }>;
      structuredContent?: { result?: T };
    };
    error?: { message?: string };
  };

  if (payload.error) throw new Error(payload.error.message ?? `TickTick MCP ${name} failed`);
  if (payload.result?.isError) {
    const message = payload.result.content?.map((item) => item.text).filter(Boolean).join("\n");
    throw new Error(message || `TickTick MCP ${name} returned an error`);
  }

  return payload.result?.structuredContent?.result as T;
}

function mcpTaskToTask(t: McpTask): TickTickTask | null {
  if (!t.id || !t.title) return null;
  const rawDate = t.due_date ?? t.start_date ?? null;
  const dueDate =
    rawDate && !t.is_all_day && hasTime(rawDate)
      ? new Date(rawDate).toISOString()
      : null;

  return {
    id: t.id,
    projectId: t.project_id ?? "",
    title: t.title,
    priority: mapPriority(t.priority),
    dueDate,
    tags: Array.isArray(t.tags) ? t.tags.filter((tag): tag is string => typeof tag === "string") : [],
    subtaskCount: Array.isArray(t.items) ? t.items.length : 0,
  };
}

async function getTodayTasksMcp(): Promise<TickTickTask[]> {
  const raw = await callTickTickMcpTool<McpTask[]>("list_undone_tasks_by_time_query", {
    query_command: "today",
  });

  const tasks = (Array.isArray(raw) ? raw : [])
    .map(mcpTaskToTask)
    .filter((task): task is TickTickTask => task !== null);

  tasks.sort((a, b) => {
    const pDiff = PRIORITY_ORDER[b.priority] - PRIORITY_ORDER[a.priority];
    if (pDiff !== 0) return pDiff;
    if (a.dueDate === null && b.dueDate === null) return 0;
    if (a.dueDate === null) return 1;
    if (b.dueDate === null) return -1;
    return a.dueDate.localeCompare(b.dueDate);
  });

  return tasks;
}

export async function completeTickTickTask(taskId: string, projectId: string): Promise<void> {
  if (process.env.TICKTICK_MCP_TOKEN) {
    await callTickTickMcpTool("complete_task", { project_id: projectId, task_id: taskId });
    return;
  }
  await completeTickTickTaskV1(taskId, projectId);
}

export async function reopenTickTickTask(taskId: string, projectId: string): Promise<void> {
  if (process.env.TICKTICK_MCP_TOKEN) {
    await callTickTickMcpTool("update_task", {
      task_id: taskId,
      task: { id: taskId, projectId, status: 0 },
    });
    return;
  }
  await reopenTickTickTaskV1(taskId, projectId);
}

// ---------------------------------------------------------------------------
// V2 API — username/password, includes Inbox
// ---------------------------------------------------------------------------

const V2_BASE = "https://api.ticktick.com/api/v2";

// Cache the session token for the process lifetime to avoid re-logging in
// on every request. Module-level state is fine in a Next.js API route (server).
let v2TokenCache: { token: string; expiresAt: number } | null = null;

async function getV2Token(): Promise<string> {
  const username = process.env.TICKTICK_USERNAME;
  const password = process.env.TICKTICK_PASSWORD;
  if (!username || !password) throw new Error("Missing TICKTICK_USERNAME / TICKTICK_PASSWORD");

  // Reuse cached token if it's still valid (cached for 12 hours)
  if (v2TokenCache && Date.now() < v2TokenCache.expiresAt) {
    return v2TokenCache.token;
  }

  const res = await fetch(`${V2_BASE}/user/signon?wc=true&remember=true`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ username, password }),
    cache: "no-store",
  });

  if (!res.ok) {
    const text = await res.text().catch(() => res.statusText);
    throw new Error(`TickTick v2 sign-in failed (${res.status}): ${text}`);
  }

  const json = await res.json() as { token?: string };
  if (!json.token) throw new Error("TickTick v2 sign-in: no token in response");

  v2TokenCache = { token: json.token, expiresAt: Date.now() + 12 * 60 * 60 * 1000 };
  return json.token;
}

async function getTodayTasksV2(): Promise<TickTickTask[]> {
  const token = await getV2Token();

  const res = await fetch(`${V2_BASE}/batch/check/0`, {
    headers: { Cookie: `t=${token}` },
    cache: "no-store",
  });

  if (!res.ok) {
    // Token may have expired — clear cache so next call re-auths
    v2TokenCache = null;
    const text = await res.text().catch(() => res.statusText);
    throw new Error(`TickTick v2 batch/check failed (${res.status}): ${text}`);
  }

  const json = await res.json() as {
    syncTaskBean?: { update?: RawTask[] };
  };

  const tasks: RawTask[] = json?.syncTaskBean?.update ?? [];
  return filterAndSort(tasks);
}

// ---------------------------------------------------------------------------
// V1 Open API — OAuth token, no Inbox access
// ---------------------------------------------------------------------------

const V1_BASE = "https://api.ticktick.com/open/v1";

function getV1Token(): string {
  const token = process.env.TICKTICK_ACCESS_TOKEN;
  if (!token || token === "undefined") {
    throw new Error("Missing TICKTICK_ACCESS_TOKEN");
  }
  return token;
}

async function completeTickTickTaskV1(taskId: string, projectId: string): Promise<void> {
  const token = getV1Token();
  const res = await fetch(`${V1_BASE}/project/${projectId}/task/${taskId}/complete`, {
    method: "POST",
    headers: { Authorization: `Bearer ${token}` },
  });

  if (!res.ok) {
    const text = await res.text().catch(() => res.statusText);
    throw new Error(text || `TickTick complete failed (${res.status})`);
  }
}

async function reopenTickTickTaskV1(taskId: string, projectId: string): Promise<void> {
  const token = getV1Token();
  const res = await fetch(`${V1_BASE}/task/${taskId}`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ taskId, projectId, status: 0 }),
  });

  if (!res.ok) {
    const text = await res.text().catch(() => res.statusText);
    throw new Error(text || `TickTick reopen failed (${res.status})`);
  }
}

async function getTodayTasksV1(): Promise<TickTickTask[]> {
  const token = process.env.TICKTICK_ACCESS_TOKEN;
  if (!token || token === "undefined") {
    throw new Error("Missing TICKTICK_ACCESS_TOKEN — run `node scripts/get-ticktick-token.mjs`");
  }

  const headers = { Authorization: `Bearer ${token}` };

  const projectsRes = await fetch(`${V1_BASE}/project`, { headers, cache: "no-store" });
  if (!projectsRes.ok) {
    const text = await projectsRes.text().catch(() => projectsRes.statusText);
    throw new Error(`TickTick projects fetch failed (${projectsRes.status}): ${text}`);
  }

  let projects: Array<{ id?: string; name?: string }>;
  try {
    projects = (await projectsRes.json()) as Array<{ id?: string }>;
  } catch {
    throw new Error("TickTick projects response was not valid JSON");
  }

  if (!Array.isArray(projects) || projects.length === 0) return [];

  const results = await Promise.allSettled(
    projects.map(async (p): Promise<RawTask[]> => {
      const id = p?.id;
      if (typeof id !== "string" || id === "") return [];

      const res = await fetch(`${V1_BASE}/project/${id}/data`, { headers, cache: "no-store" });
      if (!res.ok) return [];

      const data = await res.json().catch(() => ({})) as { tasks?: RawTask[] };
      // Tag each task with the projectId so the complete endpoint can use it
      return Array.isArray(data?.tasks)
        ? data.tasks.map((t) => ({ ...t, projectId: id }))
        : [];
    })
  );

  const allTasks = results.flatMap((r) => (r.status === "fulfilled" ? r.value : []));
  return filterAndSort(allTasks);
}

// ---------------------------------------------------------------------------
// Public API — use v2 if credentials available, else v1
// ---------------------------------------------------------------------------

export async function getTodayTasks(): Promise<TickTickTask[]> {
  if (process.env.TICKTICK_MCP_TOKEN) {
    return getTodayTasksMcp();
  }

  const hasV2Creds =
    !!process.env.TICKTICK_USERNAME && !!process.env.TICKTICK_PASSWORD;

  if (hasV2Creds) {
    return getTodayTasksV2();
  }
  return getTodayTasksV1();
}

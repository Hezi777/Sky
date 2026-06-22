import { NextRequest, NextResponse } from "next/server";

import { generateGreeting } from "@/lib/groq";
import type { DashboardAISignals, GreetingResponse } from "@/lib/types";

export const dynamic = "force-dynamic";

const periods = new Set(["morning", "afternoon", "evening", "night"]);
const loads = new Set(["unknown", "clear", "light", "busy"]);
const momentums = new Set(["unknown", "quiet", "active", "strong"]);
const trends = new Set(["unknown", "down", "flat", "up"]);
const recencies = new Set(["unknown", "recent", "stale"]);

function parseSignals(body: unknown): DashboardAISignals | null {
  if (!body || typeof body !== "object" || Array.isArray(body)) return null;
  const root = body as Record<string, unknown>;
  if (Object.keys(root).some((key) => key !== "signals")) return null;
  if (!root.signals || typeof root.signals !== "object" || Array.isArray(root.signals)) return null;

  const value = root.signals as Record<string, unknown>;
  const allowedKeys = new Set([
    "period", "calendarLoad", "taskLoad", "codingMomentum", "portfolioTrend",
    "musicPlaying", "exerciseRecency", "readingActive",
  ]);
  if (Object.keys(value).some((key) => !allowedKeys.has(key))) return null;
  if (!periods.has(value.period as string)) return null;
  if (!loads.has(value.calendarLoad as string) || !loads.has(value.taskLoad as string)) return null;
  if (!momentums.has(value.codingMomentum as string)) return null;
  if (!trends.has(value.portfolioTrend as string)) return null;
  if (!recencies.has(value.exerciseRecency as string)) return null;
  if (value.musicPlaying !== undefined && typeof value.musicPlaying !== "boolean") return null;
  if (value.readingActive !== undefined && typeof value.readingActive !== "boolean") return null;

  return value as unknown as DashboardAISignals;
}

export async function POST(req: NextRequest) {
  try {
    const body: unknown = await req.json().catch(() => null);
    const signals = parseSignals(body);
    if (!signals) {
      return NextResponse.json(
        { error: "Expected privacy-safe dashboard signals" },
        { status: 400 }
      );
    }

    const message = await generateGreeting(signals);
    return NextResponse.json<GreetingResponse>({ message });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Unknown error";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}

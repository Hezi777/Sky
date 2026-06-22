import { NextRequest, NextResponse } from "next/server";

import { generateGreeting } from "@/lib/groq";
import type { GreetingResponse } from "@/lib/types";

export const dynamic = "force-dynamic";

export async function POST(req: NextRequest) {
  try {
    const body = await req.json().catch(() => ({}));
    const events: string[] = Array.isArray(body.events) ? body.events : [];
    const tasks: string[] = Array.isArray(body.tasks) ? body.tasks : [];
    const commits = typeof body.commits === "number" ? body.commits : undefined;
    const portfolioChange = typeof body.portfolioChange === "number" ? body.portfolioChange : undefined;
    const nowPlaying = typeof body.nowPlaying === "string" ? body.nowPlaying : undefined;
    const mood = typeof body.mood === "string" ? body.mood : undefined;

    const message = await generateGreeting({ events, tasks, commits, portfolioChange, nowPlaying, mood });
    return NextResponse.json<GreetingResponse>({ message });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Unknown error";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}

import { NextResponse } from "next/server";

import { getTodayTasks } from "@/lib/ticktick";

export const dynamic = "force-dynamic";

export async function GET() {
  try {
    const tasks = await getTodayTasks();
    return NextResponse.json(tasks);
  } catch (err) {
    const error = err instanceof Error ? err.message : "Unknown error fetching TickTick tasks";
    return NextResponse.json({ error }, { status: 500 });
  }
}

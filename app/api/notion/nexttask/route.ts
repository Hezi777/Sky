import { NextResponse } from "next/server";
import { getNextTask } from "@/lib/notion";

export const dynamic = "force-dynamic";

export async function GET() {
  try {
    const task = await getNextTask();
    return NextResponse.json(task);
  } catch (err) {
    const message = err instanceof Error ? err.message : "Unknown error";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}

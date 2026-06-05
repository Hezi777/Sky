import { NextResponse } from "next/server";

import { getUpcomingEvents } from "@/lib/calendar";

export const dynamic = "force-dynamic";

export async function GET() {
  try {
    const events = await getUpcomingEvents();
    return NextResponse.json(events);
  } catch (err) {
    const error = err instanceof Error ? err.message : "Unknown error";
    return NextResponse.json({ error }, { status: 500 });
  }
}

import { NextResponse } from "next/server";

import { getSpotifyData } from "@/lib/spotify";

export const dynamic = "force-dynamic";

export async function GET() {
  try {
    const data = await getSpotifyData();
    return NextResponse.json(data);
  } catch (err) {
    const error = err instanceof Error ? err.message : "Unknown error";
    return NextResponse.json({ error }, { status: 500 });
  }
}

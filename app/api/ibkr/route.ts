import { NextResponse } from "next/server";

import { getIbkrData } from "@/lib/ibkr";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function GET() {
  try {
    const data = await getIbkrData();
    return NextResponse.json(data);
  } catch (err) {
    const error = err instanceof Error ? err.message : "Unknown error";
    return NextResponse.json({ error }, { status: 500 });
  }
}

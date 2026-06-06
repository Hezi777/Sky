import { NextResponse } from "next/server";

import { keepIbkrSessionAlive } from "@/lib/ibkr";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function POST() {
  try {
    const status = await keepIbkrSessionAlive();
    return NextResponse.json(status);
  } catch (err) {
    const error = err instanceof Error ? err.message : "Unknown error";
    const status = error.includes("needs login") ? 401 : 500;
    return NextResponse.json({ error }, { status });
  }
}

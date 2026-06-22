import { NextResponse } from "next/server";

import { getFairPrice } from "@/lib/fair";

// Scraping an undocumented endpoint — needs the Node runtime and must never
// be cached (prices update daily, source is live-fetched).
export const dynamic = "force-dynamic";
export const runtime = "nodejs";

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const fund = searchParams.get("fund")?.trim();

  if (!fund || !/^\d+$/.test(fund)) {
    return NextResponse.json(
      { error: "Missing or invalid `fund` query param (digits only)." },
      { status: 400 },
    );
  }

  const result = await getFairPrice(fund);
  if (!result) {
    return NextResponse.json(
      { error: `Could not fetch a price for fund ${fund} from Maya/TASE.` },
      { status: 500 },
    );
  }

  return NextResponse.json(result);
}

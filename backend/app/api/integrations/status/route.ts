import { NextResponse } from "next/server";

import { getIntegrationsStatus } from "@/lib/integration-status";

export const dynamic = "force-dynamic";

export async function GET() {
  return NextResponse.json(getIntegrationsStatus());
}

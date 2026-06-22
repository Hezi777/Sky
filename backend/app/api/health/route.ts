import { NextResponse } from "next/server";

import packageJson from "@/package.json";
import type { HealthResponse } from "@/lib/types";

export const dynamic = "force-dynamic";

export async function GET() {
  return NextResponse.json<HealthResponse>({
    status: "ok",
    ready: true,
    version: packageJson.version,
  });
}

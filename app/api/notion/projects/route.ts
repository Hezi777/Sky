import { NextResponse } from "next/server";
import { getActiveProjects } from "@/lib/notion";

export const dynamic = "force-dynamic";

export async function GET() {
  try {
    const projects = await getActiveProjects();
    return NextResponse.json(projects);
  } catch (err) {
    const message = err instanceof Error ? err.message : "Unknown error";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}

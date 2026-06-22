import { NextResponse } from "next/server";

import { completeTickTickTask, reopenTickTickTask } from "@/lib/ticktick";

export const dynamic = "force-dynamic";

async function readBody(req: Request) {
  const { taskId, projectId } = (await req.json()) as {
    taskId?: string;
    projectId?: string;
  };

  if (!taskId || !projectId) {
    return { error: "taskId and projectId required" } as const;
  }

  return { taskId, projectId } as const;
}

export async function POST(req: Request) {
  try {
    const body = await readBody(req);
    if ("error" in body) return NextResponse.json({ error: body.error }, { status: 400 });

    await completeTickTickTask(body.taskId, body.projectId);
    return NextResponse.json({ ok: true });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Unknown error";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}

export async function DELETE(req: Request) {
  try {
    const body = await readBody(req);
    if ("error" in body) return NextResponse.json({ error: body.error }, { status: 400 });

    await reopenTickTickTask(body.taskId, body.projectId);
    return NextResponse.json({ ok: true });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Unknown error";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}

import { NextRequest, NextResponse } from "next/server";
import { Client } from "@notionhq/client";

import { analyzeResource } from "@/lib/groq";
import type { ResourceProperties } from "@/lib/types";

export const dynamic = "force-dynamic";

const NOTION_RESOURCES_DB_ID = process.env.NOTION_RESOURCES_DB_ID ?? "";

function extractPageText(html: string): string {
  // Pull og:title, og:description, <title> from raw HTML
  const ogTitle = html.match(/<meta[^>]+property=["']og:title["'][^>]+content=["']([^"']+)["']/i)?.[1] ?? "";
  const ogDesc = html.match(/<meta[^>]+property=["']og:description["'][^>]+content=["']([^"']+)["']/i)?.[1] ?? "";
  // Also try content-before-property order
  const ogTitleAlt = html.match(/<meta[^>]+content=["']([^"']+)["'][^>]+property=["']og:title["']/i)?.[1] ?? "";
  const ogDescAlt = html.match(/<meta[^>]+content=["']([^"']+)["'][^>]+property=["']og:description["']/i)?.[1] ?? "";
  const title = html.match(/<title[^>]*>([^<]+)<\/title>/i)?.[1] ?? "";

  const blob = [ogTitle || ogTitleAlt, ogDesc || ogDescAlt, title]
    .filter(Boolean)
    .join(" | ");

  return blob.slice(0, 2000);
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const url: string = body.url;

    if (!url || typeof url !== "string") {
      return NextResponse.json({ error: "url is required" }, { status: 400 });
    }

    // Step (a): fetch the URL and extract metadata
    const fetchRes = await fetch(url, {
      headers: { "User-Agent": "Mozilla/5.0 (compatible; SkyDashboard/1.0)" },
      signal: AbortSignal.timeout(10_000),
    });
    const html = await fetchRes.text();
    const pageText = extractPageText(html);

    // Step (b): analyze with Groq
    const properties = await analyzeResource(url, pageText);

    // Step (c): write to Notion (will 404 until the integration is shared with the DB)
    const notion = new Client({ auth: process.env.NOTION_TOKEN });

    // Notion v5: retrieve DB to get data_sources[0].id
    const db = await notion.databases.retrieve({
      database_id: NOTION_RESOURCES_DB_ID,
    }) as Record<string, unknown>;

    const dataSources = db.data_sources as Array<{ id: string }> | undefined;
    const dataSourceId = dataSources?.[0]?.id ?? NOTION_RESOURCES_DB_ID;

    await notion.pages.create({
      parent: { type: "data_source_id", data_source_id: dataSourceId } as Parameters<typeof notion.pages.create>[0]["parent"],
      properties: {
        Name: { title: [{ text: { content: properties.Name } }] },
        URL: { url },
        Description: { rich_text: [{ text: { content: properties.Description } }] },
        Status: { select: { name: properties.Status } },
        Category: { multi_select: [{ name: properties.Category }] },
      },
    });

    return NextResponse.json<ResourceProperties>(properties);
  } catch (err) {
    const message = err instanceof Error ? err.message : "Unknown error";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}

import { NextResponse } from "next/server";
import { Client } from "@notionhq/client";
import type { PageObjectResponse } from "@notionhq/client/build/src/api-endpoints";

export const dynamic = "force-dynamic";

interface ReadingBook {
  id: string;
  title: string;
  author: string | null;
  currentPage: number | null;
  totalPages: number | null;
  progress: number;
  cover: string | null;
  url: string;
}

// --- Property helpers (guard everything with optional chaining) ---

function getTitleProp(page: PageObjectResponse): string {
  for (const [, prop] of Object.entries(page.properties)) {
    if (prop.type === "title") {
      return prop.title?.[0]?.plain_text ?? "";
    }
  }
  return "";
}

function getRichTextProp(page: PageObjectResponse, name: string): string | null {
  const prop = page.properties[name];
  if (!prop || prop.type !== "rich_text") return null;
  return prop.rich_text?.[0]?.plain_text ?? null;
}

function getNumberProp(page: PageObjectResponse, name: string): number | null {
  const prop = page.properties[name];
  if (!prop || prop.type !== "number") return null;
  return prop.number ?? null;
}

function getFirstFileUrl(page: PageObjectResponse, name: string): string | null {
  const prop = page.properties[name];
  if (!prop || prop.type !== "files") return null;
  const file = prop.files?.[0];
  if (!file) return null;
  if (file.type === "external") return file.external?.url ?? null;
  if (file.type === "file") return file.file?.url ?? null;
  return null;
}

function mapPage(page: PageObjectResponse): ReadingBook {
  const currentPage = getNumberProp(page, "Current Page");
  const totalPages = getNumberProp(page, "Total Pages");
  const progress =
    currentPage != null && totalPages && totalPages > 0
      ? Math.round((currentPage / totalPages) * 100)
      : 0;

  return {
    id: page.id,
    title: getTitleProp(page),
    author: getRichTextProp(page, "Author"),
    currentPage,
    totalPages,
    progress,
    cover: getFirstFileUrl(page, "Cover Image"),
    url: page.url,
  };
}

export async function GET() {
  const token = process.env.NOTION_TOKEN;
  const dataSourceId = process.env.NOTION_READING_DATA_SOURCE_ID;

  if (!token || !dataSourceId) {
    return NextResponse.json(
      { error: "Notion Reading not configured" },
      { status: 200 },
    );
  }

  try {
    const notion = new Client({ auth: token });

    const res = await notion.dataSources.query({
      data_source_id: dataSourceId,
      filter: {
        property: "Status",
        status: { equals: "Reading" },
      },
    });

    const books = res.results
      .filter((r): r is PageObjectResponse => r.object === "page")
      .map(mapPage);

    return NextResponse.json(books);
  } catch (err) {
    const message = err instanceof Error ? err.message : "Unknown error";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}

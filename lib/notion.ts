import { Client } from "@notionhq/client";
import type {
  DatabaseObjectResponse,
  PageObjectResponse,
} from "@notionhq/client/build/src/api-endpoints";
import type { NotionNextTask, NotionProject } from "@/lib/types";

const notion = new Client({ auth: process.env.NOTION_TOKEN });

const DB_ID = process.env.NOTION_PROJECTS_DB_ID ?? "";

// In-module memo: avoids re-fetching the DB on every request in dev (hot-reload aware).
let cachedDataSourceId: string | null = null;

export async function getProjectsDataSourceId(): Promise<string> {
  if (cachedDataSourceId) return cachedDataSourceId;

  const db = await notion.databases.retrieve({ database_id: DB_ID });
  // Only DatabaseObjectResponse has data_sources; guard for PartialDatabaseObjectResponse.
  const full = db as DatabaseObjectResponse;
  const id = full.data_sources?.[0]?.id;
  if (!id) throw new Error("No data_source found on projects database");
  cachedDataSourceId = id;
  return id;
}

// ---------------------------------------------------------------------------
// Property helpers — access by name, guard everything with optional chaining.
// ---------------------------------------------------------------------------

function getTitleProp(page: PageObjectResponse): string {
  for (const [, prop] of Object.entries(page.properties)) {
    if (prop.type === "title") {
      return prop.title?.[0]?.plain_text ?? "";
    }
  }
  return "";
}

function getSelectProp(page: PageObjectResponse, name: string): string | null {
  const prop = page.properties[name];
  if (!prop || prop.type !== "select") return null;
  return prop.select?.name ?? null;
}

function getRichTextProp(
  page: PageObjectResponse,
  name: string
): string | null {
  const prop = page.properties[name];
  if (!prop || prop.type !== "rich_text") return null;
  return prop.rich_text?.[0]?.plain_text ?? null;
}

function mapPage(page: PageObjectResponse): NotionProject {
  return {
    id: page.id,
    name: getTitleProp(page),
    stage: getSelectProp(page, "Stage") ?? "",
    type: getSelectProp(page, "Type"),
    stack: getRichTextProp(page, "Stack"),
    nextAction: getRichTextProp(page, "Next Action"),
    url: page.url,
  };
}

// ---------------------------------------------------------------------------
// Exported data functions
// ---------------------------------------------------------------------------

export async function getActiveProjects(): Promise<NotionProject[]> {
  const dataSourceId = await getProjectsDataSourceId();

  const res = await notion.dataSources.query({
    data_source_id: dataSourceId,
    filter: {
      and: [
        {
          or: [
            { property: "Stage", select: { equals: "In progress" } },
            { property: "Stage", select: { equals: "Finishing" } },
          ],
        },
        {
          property: "Type",
          select: { does_not_equal: "Idea" },
        },
      ],
    },
    page_size: 4,
  });

  return res.results
    .filter((r): r is PageObjectResponse => r.object === "page")
    .slice(0, 4)
    .map(mapPage);
}

export async function getNextTask(): Promise<NotionNextTask | null> {
  const dataSourceId = await getProjectsDataSourceId();

  const res = await notion.dataSources.query({
    data_source_id: dataSourceId,
    filter: {
      property: "Stage",
      select: { equals: "In progress" },
    },
    sorts: [{ timestamp: "created_time", direction: "ascending" }],
    page_size: 1,
  });

  const first = res.results.find(
    (r): r is PageObjectResponse => r.object === "page"
  );
  return first ? mapPage(first) : null;
}

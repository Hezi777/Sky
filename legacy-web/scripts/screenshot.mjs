/**
 * Takes dashboard screenshots with mocked API responses.
 * Usage: node scripts/screenshot.mjs
 * Requires: npx playwright install chromium (once)
 */
import { chromium } from "playwright";
import { spawn } from "child_process";
import { mkdirSync } from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, "..");
const OUT = path.join(ROOT, "docs", "screenshots");
mkdirSync(OUT, { recursive: true });

// ── Mock payloads ────────────────────────────────────────────────────────────

const MOCKS = {
  "/api/github": {
    repos: [
      {
        name: "sky",
        description: "Personal morning dashboard",
        language: "TypeScript",
        stars: 3,
        pushedAt: "2026-06-06T10:00:00Z",
        url: "https://github.com/demo/sky",
      },
      {
        name: "sheetsync",
        description: "Excel ↔ Google Sheets sync desktop app",
        language: "Python",
        stars: 12,
        pushedAt: "2026-05-20T08:30:00Z",
        url: "https://github.com/demo/sheetsync",
      },
      {
        name: "gryt",
        description: "Trainer client management & PDF exports",
        language: "TypeScript",
        stars: 1,
        pushedAt: "2026-04-15T14:00:00Z",
        url: "https://github.com/demo/gryt",
      },
    ],
    contributions: generateContributions(),
    totalContributions: 487,
  },

  "/api/spotify": {
    nowPlaying: {
      title: "Bohemian Rhapsody",
      artist: "Queen",
      albumArt: "https://i.scdn.co/image/ab67616d0000b273ce4f1737bc8a646c8c4bd25a",
      url: "https://open.spotify.com/track/demo",
      isPlaying: true,
      progressMs: 142000,
      durationMs: 354000,
    },
    recent: [
      {
        title: "Stairway to Heaven",
        artist: "Led Zeppelin",
        albumArt: "https://i.scdn.co/image/ab67616d0000b273c8a11e48c91a982d086afc69",
        url: "https://open.spotify.com/track/demo2",
      },
      {
        title: "Hotel California",
        artist: "Eagles",
        albumArt: "https://i.scdn.co/image/ab67616d0000b273ae3e5de03c5e0e50bcab5d04",
        url: "https://open.spotify.com/track/demo3",
      },
      {
        title: "Smells Like Teen Spirit",
        artist: "Nirvana",
        albumArt: "https://i.scdn.co/image/ab67616d0000b273fbc71c99f9c1296c56dd51b6",
        url: "https://open.spotify.com/track/demo4",
      },
    ],
  },

  "/api/calendar": [
    {
      id: "1",
      title: "Morning standup",
      start: todayAt(9, 0),
      end: todayAt(9, 30),
      allDay: false,
      location: null,
      colorId: "7",
      url: null,
    },
    {
      id: "2",
      title: "Design review",
      start: todayAt(11, 0),
      end: todayAt(12, 0),
      allDay: false,
      location: "Conference Room B",
      colorId: "9",
      url: null,
    },
    {
      id: "3",
      title: "Lunch with team",
      start: todayAt(13, 0),
      end: todayAt(14, 0),
      allDay: false,
      location: "Downtown Café",
      colorId: "11",
      url: null,
    },
    {
      id: "4",
      title: "Product planning",
      start: todayAt(15, 30),
      end: todayAt(17, 0),
      allDay: false,
      location: null,
      colorId: "6",
      url: null,
    },
    {
      id: "5",
      title: "Team offsite",
      start: tomorrowDate(),
      end: tomorrowDate(),
      allDay: true,
      location: "Tel Aviv",
      colorId: null,
      url: null,
    },
  ],

  "/api/notion/projects": [
    {
      id: "p1",
      name: "Sky Dashboard",
      stage: "In Progress",
      type: "Web App",
      stack: "Next.js · TypeScript",
      nextAction: "Add chart animations",
      url: "https://notion.so/demo",
    },
    {
      id: "p2",
      name: "SheetSync v2",
      stage: "Planning",
      type: "Desktop App",
      stack: "Python · React",
      nextAction: "Design settings screen",
      url: "https://notion.so/demo2",
    },
    {
      id: "p3",
      name: "Portfolio Site",
      stage: "In Progress",
      type: "Web App",
      stack: "Next.js · Framer",
      nextAction: "Write case studies",
      url: "https://notion.so/demo3",
    },
  ],

  "/api/notion/nexttask": {
    id: "p1",
    name: "Sky Dashboard",
    stage: "In Progress",
    type: "Web App",
    stack: "Next.js · TypeScript",
    nextAction: "Add chart animations to the GitHub heatmap widget",
    url: "https://notion.so/demo",
  },

  "/api/ticktick": [
    {
      id: "t1",
      projectId: "inbox",
      title: "Review PR #42 - calendar widget",
      priority: "high",
      dueDate: todayAt(18, 0),
      tags: ["dev"],
      subtaskCount: 0,
    },
    {
      id: "t2",
      projectId: "inbox",
      title: "Update docs for IBKR Flex setup",
      priority: "medium",
      dueDate: null,
      tags: ["docs"],
      subtaskCount: 2,
    },
    {
      id: "t3",
      projectId: "inbox",
      title: "Book flights for July trip",
      priority: "low",
      dueDate: tomorrowDate(),
      tags: ["personal"],
      subtaskCount: 0,
    },
    {
      id: "t4",
      projectId: "inbox",
      title: "Write weekly reflection",
      priority: "none",
      dueDate: null,
      tags: [],
      subtaskCount: 0,
    },
  ],

  "/api/ibkr": {
    source: "flex",
    asOf: new Date().toISOString(),
    summary: {
      totalValue: 38420.5,
      dayPnl: 312.8,
      unrealizedPnl: 4210.0,
      unrealizedPnlPercent: 12.3,
    },
    positions: [
      {
        ticker: "AAPL",
        shares: 15,
        avgCost: 172.3,
        currentPrice: 201.4,
        marketValue: 3021.0,
        pnlPercent: 16.9,
      },
      {
        ticker: "MSFT",
        shares: 10,
        avgCost: 380.0,
        currentPrice: 415.2,
        marketValue: 4152.0,
        pnlPercent: 9.3,
      },
      {
        ticker: "GOOGL",
        shares: 8,
        avgCost: 155.0,
        currentPrice: 178.6,
        marketValue: 1428.8,
        pnlPercent: 15.2,
      },
      {
        ticker: "QQQ",
        shares: 40,
        avgCost: 430.0,
        currentPrice: 488.5,
        marketValue: 19540.0,
        pnlPercent: 13.6,
      },
      {
        ticker: "VTI",
        shares: 30,
        avgCost: 235.0,
        currentPrice: 260.9,
        marketValue: 7827.0,
        pnlPercent: 11.0,
      },
    ],
  },
};

// The greeting and fair endpoints need special handling
const GREETING_MOCK = {
  message:
    "Good morning! You have 4 meetings today and 4 tasks on your list — a solid day ahead. Your portfolio is up 0.8%. Dive in.",
};

const FAIR_MOCK = {
  price: 12.34,
  asOf: "2026-06-06",
  currency: "ILS",
  source: "Maya / TASE",
  fundName: "מיטב דש מדד ת\"א 35",
};

// ── Helpers ──────────────────────────────────────────────────────────────────

function todayAt(h, m) {
  const d = new Date();
  d.setHours(h, m, 0, 0);
  return d.toISOString();
}

function tomorrowDate() {
  const d = new Date();
  d.setDate(d.getDate() + 1);
  d.setHours(10, 0, 0, 0);
  return d.toISOString();
}

function generateContributions() {
  const days = [];
  const now = new Date();
  for (let i = 364; i >= 0; i--) {
    const d = new Date(now);
    d.setDate(d.getDate() - i);
    const rand = Math.random();
    const count =
      rand < 0.45 ? 0 : rand < 0.65 ? 1 : rand < 0.8 ? 3 : rand < 0.92 ? 6 : 10;
    const level =
      count === 0 ? 0 : count <= 1 ? 1 : count <= 3 ? 2 : count <= 6 ? 3 : 4;
    days.push({
      date: d.toISOString().slice(0, 10),
      count,
      level,
    });
  }
  return days;
}

function startDevServer() {
  const server = spawn("npm", ["run", "dev"], {
    cwd: ROOT,
    env: { ...process.env, PORT: "3099" },
    stdio: "pipe",
  });
  return new Promise((resolve, reject) => {
    const timeout = setTimeout(
      () => reject(new Error("Dev server did not start in time")),
      60000,
    );
    server.stdout.on("data", (d) => {
      const s = d.toString();
      if (s.includes("localhost") || s.includes("3099") || s.includes("Ready")) {
        clearTimeout(timeout);
        resolve(server);
      }
    });
    server.stderr.on("data", (d) => {
      const s = d.toString();
      if (s.includes("localhost") || s.includes("3099") || s.includes("Ready")) {
        clearTimeout(timeout);
        resolve(server);
      }
    });
    server.on("error", reject);
  });
}

// ── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  console.log("Starting dev server...");
  const server = await startDevServer();
  // Give it a moment to stabilize
  await new Promise((r) => setTimeout(r, 3000));

  const browser = await chromium.launch({ headless: true });

  async function shot(name, setup) {
    const ctx = await browser.newContext({
      viewport: { width: 1440, height: 900 },
    });
    const page = await ctx.newPage();

    // Intercept all API calls
    await page.route("**/api/github", (r) =>
      r.fulfill({ status: 200, contentType: "application/json", body: JSON.stringify(MOCKS["/api/github"]) }),
    );
    await page.route("**/api/spotify", (r) =>
      r.fulfill({ status: 200, contentType: "application/json", body: JSON.stringify(MOCKS["/api/spotify"]) }),
    );
    await page.route("**/api/calendar", (r) =>
      r.fulfill({ status: 200, contentType: "application/json", body: JSON.stringify(MOCKS["/api/calendar"]) }),
    );
    await page.route("**/api/notion/projects", (r) =>
      r.fulfill({ status: 200, contentType: "application/json", body: JSON.stringify(MOCKS["/api/notion/projects"]) }),
    );
    await page.route("**/api/notion/nexttask", (r) =>
      r.fulfill({ status: 200, contentType: "application/json", body: JSON.stringify(MOCKS["/api/notion/nexttask"]) }),
    );
    await page.route("**/api/ticktick", (r) =>
      r.fulfill({ status: 200, contentType: "application/json", body: JSON.stringify(MOCKS["/api/ticktick"]) }),
    );
    await page.route("**/api/ibkr", (r) =>
      r.fulfill({ status: 200, contentType: "application/json", body: JSON.stringify(MOCKS["/api/ibkr"]) }),
    );
    await page.route("**/api/ai/greeting", (r) =>
      r.fulfill({ status: 200, contentType: "application/json", body: JSON.stringify(GREETING_MOCK) }),
    );
    await page.route("**/api/fair**", (r) =>
      r.fulfill({ status: 200, contentType: "application/json", body: JSON.stringify(FAIR_MOCK) }),
    );

    if (setup) await setup(page);

    await page.goto("http://localhost:3099", { waitUntil: "networkidle" });
    await page.waitForTimeout(2000);

    const file = path.join(OUT, `${name}.png`);
    await page.screenshot({ path: file, fullPage: false });
    console.log(`  saved ${name}.png`);
    await ctx.close();
  }

  async function shotFullPage(name, setup) {
    const ctx = await browser.newContext({
      viewport: { width: 1440, height: 900 },
    });
    const page = await ctx.newPage();

    await page.route("**/api/github", (r) =>
      r.fulfill({ status: 200, contentType: "application/json", body: JSON.stringify(MOCKS["/api/github"]) }),
    );
    await page.route("**/api/spotify", (r) =>
      r.fulfill({ status: 200, contentType: "application/json", body: JSON.stringify(MOCKS["/api/spotify"]) }),
    );
    await page.route("**/api/calendar", (r) =>
      r.fulfill({ status: 200, contentType: "application/json", body: JSON.stringify(MOCKS["/api/calendar"]) }),
    );
    await page.route("**/api/notion/projects", (r) =>
      r.fulfill({ status: 200, contentType: "application/json", body: JSON.stringify(MOCKS["/api/notion/projects"]) }),
    );
    await page.route("**/api/notion/nexttask", (r) =>
      r.fulfill({ status: 200, contentType: "application/json", body: JSON.stringify(MOCKS["/api/notion/nexttask"]) }),
    );
    await page.route("**/api/ticktick", (r) =>
      r.fulfill({ status: 200, contentType: "application/json", body: JSON.stringify(MOCKS["/api/ticktick"]) }),
    );
    await page.route("**/api/ibkr", (r) =>
      r.fulfill({ status: 200, contentType: "application/json", body: JSON.stringify(MOCKS["/api/ibkr"]) }),
    );
    await page.route("**/api/ai/greeting", (r) =>
      r.fulfill({ status: 200, contentType: "application/json", body: JSON.stringify(GREETING_MOCK) }),
    );
    await page.route("**/api/fair**", (r) =>
      r.fulfill({ status: 200, contentType: "application/json", body: JSON.stringify(FAIR_MOCK) }),
    );

    if (setup) await setup(page);

    await page.goto("http://localhost:3099", { waitUntil: "networkidle" });
    await page.waitForTimeout(2000);

    const file = path.join(OUT, `${name}.png`);
    await page.screenshot({ path: file, fullPage: true });
    console.log(`  saved ${name}.png`);
    await ctx.close();
  }

  console.log("Taking screenshots...");

  // Full dashboard — light mode (viewport crop)
  await shot("dashboard-light", null);

  // Full dashboard — dark mode (viewport crop)
  await shot("dashboard-dark", async (page) => {
    await page.addInitScript(() => {
      localStorage.setItem("theme", "dark");
    });
  });

  // Full page — light (all widgets)
  await shotFullPage("dashboard-full-light", null);

  // Full page — dark (all widgets)
  await shotFullPage("dashboard-full-dark", async (page) => {
    await page.addInitScript(() => {
      localStorage.setItem("theme", "dark");
    });
  });

  await browser.close();
  server.kill();
  console.log("Done.");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});

import Groq from "groq-sdk";

import type { ResourceProperties } from "@/lib/types";

let groqClient: Groq | null = null;
function getGroq(): Groq {
  if (!groqClient) groqClient = new Groq({ apiKey: process.env.GROQ_API_KEY });
  return groqClient;
}

const GREETING_MODEL = "llama-3.1-8b-instant";
const RESOURCE_MODEL = "llama-3.3-70b-versatile";

export interface GreetingInput {
  events: string[];
  tasks: string[];
  commits?: number;
  portfolioChange?: number;
  nowPlaying?: string;
  mood?: string;
}

export async function generateGreeting(input: GreetingInput): Promise<string> {
  const { events, tasks, commits, portfolioChange, nowPlaying, mood } = input;
  const hour = new Date().getHours();
  const period =
    hour < 12 ? "morning" : hour < 18 ? "afternoon" : "evening";

  const parts: string[] = [];
  parts.push(`Time: ${period}.`);
  if (mood) parts.push(`Mood: ${mood}.`);
  if (events.length > 0) parts.push(`Today's events: ${events.join(", ")}.`);
  if (tasks.length > 0) parts.push(`Tasks due: ${tasks.join(", ")}.`);
  if (commits !== undefined && commits > 0) parts.push(`GitHub commits today: ${commits}.`);
  if (portfolioChange !== undefined) parts.push(`Portfolio change: ${portfolioChange > 0 ? "+" : ""}${portfolioChange.toFixed(1)}%.`);
  if (nowPlaying) parts.push(`Listening to: ${nowPlaying}.`);

  const hasContext = events.length > 0 || tasks.length > 0 || commits || portfolioChange !== undefined || nowPlaying;
  const userMessage = hasContext
    ? parts.join(" ")
    : `It is ${period}. Give a warm generic ${period} greeting.`;

  const completion = await getGroq().chat.completions.create({
    model: GREETING_MODEL,
    messages: [
      {
        role: "system",
        content:
          "You are a concise personal agent. Given data signals (commits, portfolio %, tasks, music), produce ONE short friendly sentence (12-22 words) that weaves the numbers naturally. Sound like a smart friend giving a quick status update — grounded, specific, warm. Never be poetic, flowery, or ominous. No preamble, no quotes, no emoji.",
      },
      { role: "user", content: userMessage },
    ],
    max_tokens: 80,
  });

  return completion.choices[0]?.message?.content?.trim() ?? "Have a great day!";
}

export async function analyzeResource(
  url: string,
  pageText: string
): Promise<ResourceProperties> {
  const completion = await getGroq().chat.completions.create({
    model: RESOURCE_MODEL,
    messages: [
      {
        role: "system",
        content:
          'You analyze URLs and return structured metadata as JSON. Always return valid JSON with these exact keys: Name (string), Description (string, max 80 chars - one short plain-language phrase describing what it does and why it\'s useful, no marketing fluff, no trailing period), Category (exactly one of: "Claude Code", "UI Components", "Design Inspo", "AI Tools", "Dev Infrastructure", "SaaS/Biz", "Learning", "BI/Data", "Tools", "GitHub"), Status (always "Saved").',
      },
      {
        role: "user",
        content: `URL: ${url}\n\nPage content:\n${pageText}`,
      },
    ],
    response_format: { type: "json_object" },
    max_tokens: 256,
  });

  const raw = completion.choices[0]?.message?.content ?? "{}";

  let parsed: Partial<ResourceProperties>;
  try {
    parsed = JSON.parse(raw);
  } catch {
    parsed = {};
  }

  return {
    Name: parsed.Name ?? new URL(url).hostname,
    Description: (parsed.Description ?? "").slice(0, 80),
    Category: parsed.Category ?? "Tools",
    Status: "Saved",
  };
}

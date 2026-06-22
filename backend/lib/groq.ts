import Groq from "groq-sdk";

import type { DashboardAISignals, ResourceProperties } from "@/lib/types";

let groqClient: Groq | null = null;
function getGroq(): Groq {
  if (!groqClient) groqClient = new Groq({ apiKey: process.env.GROQ_API_KEY });
  return groqClient;
}

const GREETING_MODEL = "llama-3.1-8b-instant";
const RESOURCE_MODEL = "llama-3.3-70b-versatile";

export async function generateGreeting(signals: DashboardAISignals): Promise<string> {
  const completion = await getGroq().chat.completions.create({
    model: GREETING_MODEL,
    messages: [
      {
        role: "system",
        content:
          "You are a concise personal dashboard. Given only coarse status categories, produce one short friendly sentence (12-22 words). Be grounded and calm. Never infer names, titles, money, exact counts, places, or details that are not present. No preamble, quotes, emoji, poetry, or ominous language.",
      },
      { role: "user", content: JSON.stringify(signals) },
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

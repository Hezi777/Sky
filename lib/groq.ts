import Groq from "groq-sdk";

import type { ResourceProperties } from "@/lib/types";

const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });

const GREETING_MODEL = "llama-3.1-8b-instant";
const RESOURCE_MODEL = "llama-3.3-70b-versatile";

export async function generateGreeting(input: {
  events: string[];
  tasks: string[];
}): Promise<string> {
  const { events, tasks } = input;
  const hour = new Date().getHours();
  const period =
    hour < 12 ? "morning" : hour < 18 ? "afternoon" : "evening";

  let context = "";
  if (events.length > 0) context += `Today's events: ${events.join(", ")}. `;
  if (tasks.length > 0) context += `Tasks due: ${tasks.join(", ")}.`;

  const userMessage =
    context.trim() ||
    `It is ${period}. No events or tasks were provided. Give a warm generic ${period} greeting.`;

  const completion = await groq.chat.completions.create({
    model: GREETING_MODEL,
    messages: [
      {
        role: "system",
        content:
          "You are a friendly personal assistant. Return ONLY one short sentence under 18 words. Match the provided time of day. No preamble, no quotes.",
      },
      { role: "user", content: userMessage },
    ],
    max_tokens: 60,
  });

  return completion.choices[0]?.message?.content?.trim() ?? "Have a great day!";
}

export async function analyzeResource(
  url: string,
  pageText: string
): Promise<ResourceProperties> {
  const completion = await groq.chat.completions.create({
    model: RESOURCE_MODEL,
    messages: [
      {
        role: "system",
        content:
          'You analyze URLs and return structured metadata as JSON. Always return valid JSON with these exact keys: Name (string), Description (string, max 120 chars), Category (exactly one of: "Claude Code", "UI Components", "Design Inspo", "AI Tools", "Dev Infrastructure", "SaaS/Biz", "Learning", "BI/Data", "Tools", "GitHub"), Status (always "Saved").',
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
    Description: (parsed.Description ?? "").slice(0, 120),
    Category: parsed.Category ?? "Tools",
    Status: "Saved",
  };
}

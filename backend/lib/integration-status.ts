import type {
  IntegrationConfigStatus,
  IntegrationsStatusResponse,
} from "@/lib/types";

type Env = Record<string, string | undefined>;

function has(env: Env, key: string): boolean {
  return Boolean(env[key]?.trim());
}

function required(env: Env, keys: string[]): IntegrationConfigStatus {
  const missing = keys.filter((key) => !has(env, key));
  return { configured: missing.length === 0, missing };
}

function alternatives(env: Env, paths: string[][]): IntegrationConfigStatus {
  const configured = paths.some((path) => path.every((key) => has(env, key)));
  const keys = [...new Set(paths.flat())];
  return {
    configured,
    missing: configured ? [] : keys.filter((key) => !has(env, key)),
  };
}

function ibkrStatus(env: Env): IntegrationConfigStatus {
  const source = env.IBKR_DATA_SOURCE?.trim();
  const flex = ["IBKR_FLEX_TOKEN", "IBKR_FLEX_QUERY_ID"];
  const gateway = ["IBKR_GATEWAY_URL"];

  if (source === "flex") return required(env, flex);
  if (source === "gateway") return required(env, gateway);
  return alternatives(env, [flex, gateway]);
}

export function getIntegrationsStatus(
  env: Env = process.env,
): IntegrationsStatusResponse {
  return {
    integrations: {
      googleCalendar: required(env, [
        "GOOGLE_CLIENT_ID",
        "GOOGLE_CLIENT_SECRET",
        "GOOGLE_REFRESH_TOKEN",
      ]),
      tickTick: alternatives(env, [
        ["TICKTICK_MCP_TOKEN"],
        ["TICKTICK_USERNAME", "TICKTICK_PASSWORD"],
        ["TICKTICK_ACCESS_TOKEN"],
      ]),
      spotify: required(env, [
        "SPOTIFY_CLIENT_ID",
        "SPOTIFY_CLIENT_SECRET",
        "SPOTIFY_REFRESH_TOKEN",
      ]),
      strava: required(env, [
        "STRAVA_CLIENT_ID",
        "STRAVA_CLIENT_SECRET",
        "STRAVA_REFRESH_TOKEN",
      ]),
      stocks: required(env, ["FINNHUB_API_KEY"]),
      github: required(env, ["GITHUB_PAT"]),
      notionReading: required(env, [
        "NOTION_TOKEN",
        "NOTION_READING_DATA_SOURCE_ID",
      ]),
      ibkr: ibkrStatus(env),
      groq: required(env, ["GROQ_API_KEY"]),
    },
  };
}

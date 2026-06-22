/**
 * IBKR Client Portal Gateway connector.
 *
 * Requires the official IBKR Client Portal Gateway (a local Java app) running
 * at https://localhost:5001 and authenticated in your browser.
 */

import { request, Agent } from "node:https";

import { getIbkrFlexData, hasIbkrFlexConfig } from "@/lib/ibkr-flex";
import type { IbkrPosition, IbkrResponse, IbkrSummary } from "@/lib/types";

const BASE = process.env.IBKR_GATEWAY_URL ?? "https://localhost:5001";
const IBKR_HEADERS = {
  Accept: "application/json",
  "User-Agent":
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
};

const httpsAgent = new Agent({ rejectUnauthorized: false });

type IbkrDataSource = "auto" | "gateway" | "flex";

class IbkrAuthError extends Error {
  constructor() {
    super(`IBKR gateway needs login. Open ${BASE} and sign in.`);
  }
}

type IbkrMethod = "GET" | "POST";

// eslint-disable-next-line @typescript-eslint/no-explicit-any
async function ibkrFetch(path: string, method: IbkrMethod = "GET"): Promise<any> {
  const url = new URL(path, BASE);
  const headers =
    method === "POST"
      ? { ...IBKR_HEADERS, "Content-Length": "0" }
      : IBKR_HEADERS;

  return new Promise((resolve, reject) => {
    const req = request(url, { agent: httpsAgent, headers, method }, (res) => {
      let body = "";
      res.setEncoding("utf8");
      res.on("data", (chunk) => {
        body += chunk;
      });
      res.on("end", () => {
        if (res.statusCode === 401 || res.statusCode === 403) {
          reject(new IbkrAuthError());
          return;
        }
        if (!res.statusCode || res.statusCode < 200 || res.statusCode >= 300) {
          reject(new Error(`IBKR ${path} -> ${res.statusCode ?? "unknown"}`));
          return;
        }
        try {
          resolve(body ? JSON.parse(body) : null);
        } catch {
          reject(new Error(`IBKR ${path} returned invalid JSON`));
        }
      });
    });

    req.setTimeout(10_000, () => {
      req.destroy(new Error("IBKR gateway request timed out"));
    });
    req.on("error", reject);
    req.end();
  });
}

export async function keepIbkrSessionAlive(): Promise<{
  authenticated: boolean;
  connected: boolean;
  skipped?: boolean;
}> {
  if ((process.env.IBKR_DATA_SOURCE as IbkrDataSource | undefined) === "flex") {
    return { authenticated: false, connected: false, skipped: true };
  }

  const status = await ibkrFetch("/v1/api/iserver/auth/status");
  const authenticated = status?.authenticated === true;
  const connected = status?.connected === true;

  if (authenticated) {
    await ibkrFetch("/v1/api/tickle", "POST");
    return { authenticated: true, connected };
  }

  if (connected) {
    await ibkrFetch("/v1/api/iserver/auth/ssodh/init", "POST");
    const next = await ibkrFetch("/v1/api/iserver/auth/status");
    if (next?.authenticated === true) {
      await ibkrFetch("/v1/api/tickle", "POST");
      return { authenticated: true, connected: next?.connected === true };
    }
  }

  throw new IbkrAuthError();
}

async function resolveAccountId(): Promise<string> {
  if (process.env.IBKR_ACCOUNT_ID) return process.env.IBKR_ACCOUNT_ID;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const accounts: any[] = await ibkrFetch("/v1/api/portfolio/accounts");
  const id = accounts?.[0]?.id ?? accounts?.[0]?.accountId;
  if (!id) throw new Error("IBKR: no account id found");
  return String(id);
}

function amountFromField(field: unknown): number | null {
  if (typeof field === "number" && Number.isFinite(field)) return field;
  if (typeof field === "string") {
    const n = Number.parseFloat(field.replace(/,/g, ""));
    return Number.isFinite(n) ? n : null;
  }
  if (field && typeof field === "object") {
    const record = field as Record<string, unknown>;
    return (
      amountFromField(record.amount) ??
      amountFromField(record.value) ??
      amountFromField(record.raw)
    );
  }
  return null;
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function amount(raw: any, keys: string[]): number | null {
  for (const key of keys) {
    const value = amountFromField(raw[key]);
    if (value !== null) return value;
  }
  return null;
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function parseSummary(raw: any, positions: IbkrPosition[]): IbkrSummary {
  const marketValue = positions.reduce((sum, p) => sum + p.marketValue, 0);
  const costBasis = positions.reduce((sum, p) => sum + p.avgCost * p.shares, 0);
  const derivedUnrealizedPnl = marketValue - costBasis;

  const totalValue =
    amount(raw, ["netliquidation", "NetLiquidation", "net_liquidation"]) ??
    marketValue;
  const dayPnl = amount(raw, ["dayplnl", "DayPnL", "day_pnl", "dpl"]);
  const unrealizedPnl =
    amount(raw, ["unrealizedpnl", "UnrealizedPnL", "unrealized_pnl", "upl"]) ??
    derivedUnrealizedPnl;
  const unrealizedPnlPercent =
    costBasis !== 0 ? (unrealizedPnl / costBasis) * 100 : 0;

  return { totalValue, dayPnl, unrealizedPnl, unrealizedPnlPercent };
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function parsePositions(raw: any[]): IbkrPosition[] {
  if (!Array.isArray(raw)) return [];
  return raw
    .filter(Boolean)
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    .map((p: any): IbkrPosition => {
      const ticker: string =
        p.contractDesc ?? p.ticker ?? p.symbol ?? p.conid?.toString() ?? "—";
      const shares: number = p.position ?? p.shares ?? 0;
      const avgCost: number = p.avgCost ?? p.averageCost ?? p.avg_cost ?? 0;
      const currentPrice: number = p.mktPrice ?? p.marketPrice ?? p.last_price ?? 0;
      const marketValue: number = p.mktValue ?? p.marketValue ?? p.market_value ?? 0;
      const pnlPercent: number =
        avgCost !== 0 ? ((currentPrice - avgCost) / avgCost) * 100 : 0;
      return { ticker, shares, avgCost, currentPrice, marketValue, pnlPercent };
    });
}

async function getIbkrGatewayData(): Promise<IbkrResponse> {
  const accountId = await resolveAccountId();
  const [summaryRaw, positionsRaw] = await Promise.all([
    ibkrFetch(`/v1/api/portfolio/${accountId}/summary`),
    ibkrFetch(`/v1/api/portfolio/${accountId}/positions/0`),
  ]);
  const positions = parsePositions(positionsRaw);
  return {
    source: "gateway",
    asOf: new Date().toISOString(),
    summary: parseSummary(summaryRaw, positions),
    positions,
  };
}

function dataSource(): IbkrDataSource {
  const value = process.env.IBKR_DATA_SOURCE;
  if (value === "gateway" || value === "flex" || value === "auto") return value;
  return "auto";
}

export async function getIbkrData(): Promise<IbkrResponse> {
  const source = dataSource();

  if (source === "flex") return getIbkrFlexData();
  if (source === "gateway") return getIbkrGatewayData();

  if (hasIbkrFlexConfig()) return getIbkrFlexData();
  return getIbkrGatewayData();
}

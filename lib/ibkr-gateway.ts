/**
 * IBKR Client Portal Gateway connector (legacy fallback).
 *
 * This was the original implementation. It requires the IBKR Client Portal Gateway
 * (a Java app) to be running locally at https://localhost:5000 and authenticated.
 * It is kept here as a documented fallback in case the SnapTrade-based connector
 * (lib/ibkr.ts) is unavailable.
 *
 * To switch back: replace the contents of lib/ibkr.ts with this file, and
 * restore the IBKR_GATEWAY_URL / IBKR_ACCOUNT_ID env vars.
 */

import { Agent } from "undici";

import type { IbkrPosition, IbkrResponse, IbkrSummary } from "@/lib/types";

const BASE = process.env.IBKR_GATEWAY_URL ?? "https://localhost:5000";

// The IBKR Client Portal gateway uses a self-signed certificate.
// We disable TLS verification via an undici Agent and pass it as dispatcher.
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const dispatcher = new Agent({ connect: { rejectUnauthorized: false } } as any);

// eslint-disable-next-line @typescript-eslint/no-explicit-any
async function ibkrFetch(path: string): Promise<any> {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const res = await (fetch as any)(`${BASE}${path}`, { dispatcher });
  if (!res.ok) throw new Error(`IBKR ${path} → ${res.status}`);
  return res.json();
}

async function resolveAccountId(): Promise<string> {
  if (process.env.IBKR_ACCOUNT_ID) return process.env.IBKR_ACCOUNT_ID;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const accounts: any[] = await ibkrFetch("/v1/api/portfolio/accounts");
  const id = accounts?.[0]?.id ?? accounts?.[0]?.accountId;
  if (!id) throw new Error("IBKR: no account id found");
  return String(id);
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function parseSummary(raw: any): IbkrSummary {
  function amount(key: string): number {
    const field = raw[key];
    if (field === undefined) return 0;
    if (typeof field === "number") return field;
    return (field.amount as number) ?? 0;
  }

  const totalValue = amount("netliquidation") || amount("NetLiquidation") || amount("net_liquidation");
  const dayPnl = amount("dayplnl") || amount("DayPnL") || amount("day_pnl") || amount("dpl");
  const unrealizedRaw =
    amount("unrealizedpnl") || amount("UnrealizedPnL") || amount("unrealized_pnl") || amount("upl");
  const unrealizedPnlPercent = totalValue !== 0 ? (unrealizedRaw / totalValue) * 100 : 0;

  return { totalValue, dayPnl, unrealizedPnlPercent };
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

export async function getIbkrData(): Promise<IbkrResponse> {
  const accountId = await resolveAccountId();
  const [summaryRaw, positionsRaw] = await Promise.all([
    ibkrFetch(`/v1/api/portfolio/${accountId}/summary`),
    ibkrFetch(`/v1/api/portfolio/${accountId}/positions/0`),
  ]);
  return {
    summary: parseSummary(summaryRaw),
    positions: parsePositions(positionsRaw),
  };
}

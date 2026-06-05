/**
 * IBKR portfolio connector — powered by SnapTrade.
 *
 * SnapTrade is a hosted brokerage-data aggregator that supports IBKR via
 * IBKR Flex Query. It eliminates the need to run the IBKR Client Portal
 * Gateway (a local Java process) and re-authenticate manually.
 *
 * Fallback (local gateway): see lib/ibkr-gateway.ts.
 *
 * Required env vars (see .env.local.example):
 *   SNAPTRADE_CLIENT_ID      – from dashboard.snaptrade.com
 *   SNAPTRADE_CONSUMER_KEY   – from dashboard.snaptrade.com
 *   SNAPTRADE_USER_ID        – stable identifier for this user (any string, e.g. "hen")
 *   SNAPTRADE_USER_SECRET    – returned when you first register the user; store it permanently
 *   SNAPTRADE_ACCOUNT_ID     – SnapTrade account UUID for the IBKR account (from listAccounts)
 *
 * One-time setup: run `npx ts-node scripts/snaptrade-setup.ts` (or follow AGENTS.md)
 * to register the user and get the connection portal URL for linking your IBKR account.
 */

import { Snaptrade } from "snaptrade-typescript-sdk";

import type { IbkrPosition, IbkrResponse, IbkrSummary } from "@/lib/types";

function getClient(): Snaptrade {
  const clientId = process.env.SNAPTRADE_CLIENT_ID;
  const consumerKey = process.env.SNAPTRADE_CONSUMER_KEY;
  if (!clientId || !consumerKey) {
    throw new Error(
      "SNAPTRADE_CLIENT_ID and SNAPTRADE_CONSUMER_KEY must be set. " +
        "See .env.local.example and AGENTS.md for setup instructions.",
    );
  }
  return new Snaptrade({ clientId, consumerKey });
}

function requireEnv(name: string): string {
  const v = process.env[name];
  if (!v) throw new Error(`${name} env var is not set. Run scripts/snaptrade-setup.ts first.`);
  return v;
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function parsePositions(raw: any[]): IbkrPosition[] {
  if (!Array.isArray(raw)) return [];
  return raw
    .filter(Boolean)
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    .map((p: any): IbkrPosition => {
      // SnapTrade positions: p.symbol.symbol.symbol is the ticker string
      const ticker: string =
        p.symbol?.symbol?.symbol ??
        p.symbol?.symbol?.raw_symbol ??
        p.symbol?.symbol?.id ??
        "—";
      const shares: number = p.units ?? p.fractional_units ?? 0;
      const avgCost: number = p.average_purchase_price ?? 0;
      const currentPrice: number = p.price ?? 0;
      // market value: units * price (SnapTrade doesn't return market_value directly)
      const marketValue: number = shares * currentPrice;
      const pnlPercent: number =
        avgCost !== 0 ? ((currentPrice - avgCost) / avgCost) * 100 : 0;
      return { ticker, shares, avgCost, currentPrice, marketValue, pnlPercent };
    });
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function parseSummary(balances: any[], totalValue: number): IbkrSummary {
  // SnapTrade doesn't expose intraday P&L — return 0 for dayPnl.
  // unrealizedPnlPercent is derived from positions in the caller.
  const cash = Array.isArray(balances)
    ? balances.reduce((sum, b) => sum + (b.cash ?? 0), 0)
    : 0;
  void cash; // informational only; not in IbkrSummary
  return {
    totalValue,
    dayPnl: 0, // SnapTrade / Flex Query does not surface intraday P&L
    unrealizedPnlPercent: 0, // filled in below after positions are parsed
  };
}

export async function getIbkrData(): Promise<IbkrResponse> {
  const snaptrade = getClient();
  const userId = requireEnv("SNAPTRADE_USER_ID");
  const userSecret = requireEnv("SNAPTRADE_USER_SECRET");
  const accountId = requireEnv("SNAPTRADE_ACCOUNT_ID");

  // Fetch holdings (positions + balances) in parallel
  const [positionsRes, balancesRes] = await Promise.all([
    snaptrade.accountInformation.getUserAccountPositions({
      userId,
      userSecret,
      accountId,
    }),
    snaptrade.accountInformation.getUserAccountBalance({
      userId,
      userSecret,
      accountId,
    }),
  ]);

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const rawPositions: any[] = (positionsRes as any).data ?? [];
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const rawBalances: any[] = (balancesRes as any).data ?? [];

  const positions = parsePositions(rawPositions);

  // Total value: sum of all balance.cash entries, or fall back to summing market values
  const totalFromBalances = Array.isArray(rawBalances)
    ? rawBalances.reduce(
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        (sum: number, b: any) => sum + (b.cash ?? 0) + (b.buying_power ?? 0),
        0,
      )
    : 0;
  const totalFromPositions = positions.reduce((s, p) => s + p.marketValue, 0);
  // Prefer balance-based total (includes cash), fall back to positions sum
  const totalValue = totalFromBalances > 0 ? totalFromBalances : totalFromPositions;

  const summary = parseSummary(rawBalances, totalValue);

  // Derive unrealized P&L % from aggregate positions
  const totalCostBasis = positions.reduce((s, p) => s + p.avgCost * p.shares, 0);
  if (totalCostBasis > 0) {
    const totalPnl = totalFromPositions - totalCostBasis;
    summary.unrealizedPnlPercent = (totalPnl / totalCostBasis) * 100;
  }

  return { summary, positions };
}

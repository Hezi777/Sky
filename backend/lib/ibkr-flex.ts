import { XMLParser } from "fast-xml-parser";

import type { IbkrPosition, IbkrResponse, IbkrSummary } from "@/lib/types";

const FLEX_BASE =
  "https://ndcdyn.interactivebrokers.com/AccountManagement/FlexWebService";
const FLEX_VERSION = "3";
const DEFAULT_CACHE_MS = 15 * 60_000;
const FLEX_HEADERS = {
  Accept: "application/xml,text/xml,*/*",
  "User-Agent": "Sky Dashboard/1.0",
};

const parser = new XMLParser({
  ignoreAttributes: false,
  attributeNamePrefix: "",
  parseAttributeValue: true,
  trimValues: true,
});

let cache: { expiresAt: number; data: IbkrResponse } | null = null;

export function hasIbkrFlexConfig(): boolean {
  return Boolean(process.env.IBKR_FLEX_TOKEN && process.env.IBKR_FLEX_QUERY_ID);
}

function cacheMs(): number {
  const value = Number(process.env.IBKR_FLEX_CACHE_MS);
  return Number.isFinite(value) && value > 0 ? value : DEFAULT_CACHE_MS;
}

function asArray<T>(value: T | T[] | null | undefined): T[] {
  if (Array.isArray(value)) return value;
  return value == null ? [] : [value];
}

function asRecord(value: unknown): Record<string, unknown> {
  return value && typeof value === "object" ? (value as Record<string, unknown>) : {};
}

function textField(source: Record<string, unknown>, key: string): string | null {
  const value = source[key];
  if (typeof value === "string") return value;
  if (typeof value === "number") return String(value);
  if (value && typeof value === "object") {
    const record = value as Record<string, unknown>;
    const text = record["#text"];
    if (typeof text === "string" || typeof text === "number") return String(text);
  }
  return null;
}

function numberField(source: Record<string, unknown>, keys: string[]): number | null {
  for (const key of keys) {
    const value = source[key];
    if (typeof value === "number" && Number.isFinite(value)) return value;
    if (typeof value === "string") {
      const parsed = Number.parseFloat(value.replace(/,/g, ""));
      if (Number.isFinite(parsed)) return parsed;
    }
  }
  return null;
}

function collectByKey(value: unknown, key: string, out: Record<string, unknown>[] = []) {
  if (Array.isArray(value)) {
    value.forEach((item) => collectByKey(item, key, out));
    return out;
  }

  if (!value || typeof value !== "object") return out;

  for (const [childKey, childValue] of Object.entries(value)) {
    if (childKey === key) {
      asArray(childValue).forEach((item) => out.push(asRecord(item)));
    } else {
      collectByKey(childValue, key, out);
    }
  }

  return out;
}

async function flexRequest(path: string, params: Record<string, string>): Promise<string> {
  const url = new URL(`${FLEX_BASE}${path}`);
  for (const [key, value] of Object.entries(params)) {
    url.searchParams.set(key, value);
  }

  const res = await fetch(url, {
    headers: FLEX_HEADERS,
    cache: "no-store",
  });

  const text = await res.text();
  if (!res.ok) {
    throw new Error(`IBKR Flex ${path} failed (${res.status}): ${text.slice(0, 240)}`);
  }

  return text;
}

function parseSendResponse(xml: string): string {
  const parsed = asRecord(parser.parse(xml));
  const response = asRecord(parsed.FlexStatementResponse ?? parsed.FlexStatement);
  const status = textField(response, "Status");

  if (status !== "Success") {
    const code = textField(response, "ErrorCode");
    const message = textField(response, "ErrorMessage") ?? "Unknown Flex error";
    throw new Error(`IBKR Flex request failed${code ? ` (${code})` : ""}: ${message}`);
  }

  const referenceCode = textField(response, "ReferenceCode");
  if (!referenceCode) throw new Error("IBKR Flex did not return a reference code");
  return referenceCode;
}

function parseStatementOrThrow(xml: string): Record<string, unknown> {
  const parsed = asRecord(parser.parse(xml));
  const response = asRecord(parsed.FlexStatementResponse);
  const status = textField(response, "Status");

  if (status === "Fail") {
    const code = textField(response, "ErrorCode");
    const message = textField(response, "ErrorMessage") ?? "Unknown Flex error";
    throw new Error(`IBKR Flex statement failed${code ? ` (${code})` : ""}: ${message}`);
  }

  return parsed;
}

function parseFlexPositions(statement: Record<string, unknown>): IbkrPosition[] {
  const rawPositions = collectByKey(statement, "OpenPosition")
    .map((raw) => {
      const shares = numberField(raw, ["position", "quantity", "qty"]) ?? 0;
      const avgCost = numberField(raw, ["costBasisPrice", "costPrice", "avgCost"]) ?? 0;
      const currentPrice = numberField(raw, ["markPrice", "closePrice", "price"]) ?? 0;
      const marketValue =
        numberField(raw, ["positionValue", "value", "baseValue", "marketValue"]) ??
        shares * currentPrice;
      const costBasis =
        numberField(raw, ["costBasisMoney", "costBasis", "costBasisValue"]) ??
        shares * avgCost;
      const unrealizedPnl =
        numberField(raw, ["fifoPnlUnrealized", "unrealizedPnl", "unrealizedPnL"]) ??
        marketValue - costBasis;
      const ticker =
        textField(raw, "symbol") ??
        textField(raw, "underlyingSymbol") ??
        textField(raw, "description") ??
        textField(raw, "conid") ??
        "—";
      const pnlPercent = costBasis !== 0 ? (unrealizedPnl / Math.abs(costBasis)) * 100 : 0;

      return { ticker, shares, avgCost, currentPrice, marketValue, pnlPercent, costBasis };
    })
    .filter((position) => position.ticker !== "—" || position.marketValue !== 0);

  const grouped = new Map<string, typeof rawPositions>();
  for (const position of rawPositions) {
    const key = position.ticker.trim().toUpperCase();
    grouped.set(key, [...(grouped.get(key) ?? []), position]);
  }

  return [...grouped.values()].map((group) => {
    const summaryRow = group.find((position, index) => {
      const rest = group.filter((_, restIndex) => restIndex !== index);
      if (rest.length === 0) return false;
      const restShares = rest.reduce((sum, item) => sum + item.shares, 0);
      const restMarketValue = rest.reduce((sum, item) => sum + item.marketValue, 0);
      return (
        Math.abs(position.shares - restShares) < 0.0001 ||
        Math.abs(position.marketValue - restMarketValue) < 0.01
      );
    });

    if (summaryRow) {
      return {
        ticker: summaryRow.ticker,
        shares: summaryRow.shares,
        avgCost: summaryRow.avgCost,
        currentPrice: summaryRow.currentPrice,
        marketValue: summaryRow.marketValue,
        pnlPercent: summaryRow.pnlPercent,
      };
    }

    const [first] = group;
    const shares = group.reduce((sum, item) => sum + item.shares, 0);
    const marketValue = group.reduce((sum, item) => sum + item.marketValue, 0);
    const costBasis = group.reduce((sum, item) => sum + item.costBasis, 0);
    const currentPrice = shares !== 0 ? marketValue / shares : first.currentPrice;
    const avgCost = shares !== 0 ? costBasis / shares : first.avgCost;
    const pnlPercent = costBasis !== 0 ? ((marketValue - costBasis) / Math.abs(costBasis)) * 100 : 0;

    return {
      ticker: first.ticker,
      shares,
      avgCost,
      currentPrice,
      marketValue,
      pnlPercent,
    };
  });
}

function parseFlexDayPnl(statement: Record<string, unknown>): number | null {
  const rows = collectByKey(statement, "MTMPerformanceSummaryUnderlying");
  if (rows.length === 0) return null;

  const aggregate = rows.find((row) => {
    const symbol = textField(row, "symbol")?.trim() ?? "";
    const assetCategory = textField(row, "assetCategory")?.trim() ?? "";
    return !symbol && !assetCategory;
  });
  const aggregateTotal = aggregate ? numberField(aggregate, ["total", "Total"]) : null;
  if (aggregateTotal !== null) return aggregateTotal;

  const summed = rows.reduce((sum, row) => {
    const assetCategory = textField(row, "assetCategory")?.trim().toUpperCase() ?? "";
    const symbol = textField(row, "symbol")?.trim() ?? "";
    if (assetCategory === "CASH" || (!assetCategory && !symbol)) return sum;
    return sum + (numberField(row, ["total", "Total"]) ?? 0);
  }, 0);

  return Number.isFinite(summed) ? summed : null;
}

function parseFlexSummary(
  statement: Record<string, unknown>,
  positions: IbkrPosition[],
): IbkrSummary {
  const marketValue = positions.reduce((sum, p) => sum + p.marketValue, 0);
  const costBasis = positions.reduce((sum, p) => sum + p.avgCost * p.shares, 0);
  const derivedUnrealizedPnl = marketValue - costBasis;

  const navRows = [
    ...collectByKey(statement, "NetAssetValue"),
    ...collectByKey(statement, "EquitySummaryInBase"),
  ];
  const navTotal =
    navRows
      .map((row) =>
        numberField(row, [
          "endingValue",
          "value",
          "total",
          "netAssetValue",
          "totalValue",
          "amount",
        ]),
      )
      .find((value): value is number => value !== null) ?? null;

  const unrealizedPnl = positions.reduce((sum, p) => {
    const basis = p.avgCost * p.shares;
    return sum + (p.marketValue - basis);
  }, 0);

  return {
    totalValue: navTotal ?? marketValue,
    dayPnl: parseFlexDayPnl(statement),
    unrealizedPnl: Number.isFinite(unrealizedPnl) ? unrealizedPnl : derivedUnrealizedPnl,
    unrealizedPnlPercent:
      costBasis !== 0 ? ((Number.isFinite(unrealizedPnl) ? unrealizedPnl : derivedUnrealizedPnl) / Math.abs(costBasis)) * 100 : 0,
  };
}

export async function getIbkrFlexData(): Promise<IbkrResponse> {
  if (!hasIbkrFlexConfig()) {
    throw new Error("IBKR Flex is not configured. Add IBKR_FLEX_TOKEN and IBKR_FLEX_QUERY_ID.");
  }

  if (cache && cache.expiresAt > Date.now()) return cache.data;

  const token = process.env.IBKR_FLEX_TOKEN!;
  const queryId = process.env.IBKR_FLEX_QUERY_ID!;
  const sendXml = await flexRequest("/SendRequest", {
    t: token,
    q: queryId,
    v: FLEX_VERSION,
  });
  const referenceCode = parseSendResponse(sendXml);

  let statement: Record<string, unknown> | null = null;
  let lastError: unknown = null;

  for (let attempt = 0; attempt < 3; attempt += 1) {
    if (attempt > 0) await new Promise((resolve) => setTimeout(resolve, 1500));
    try {
      const statementXml = await flexRequest("/GetStatement", {
        t: token,
        q: referenceCode,
        v: FLEX_VERSION,
      });
      statement = parseStatementOrThrow(statementXml);
      break;
    } catch (err) {
      lastError = err;
    }
  }

  if (!statement) throw lastError instanceof Error ? lastError : new Error("IBKR Flex report was not ready");

  const positions = parseFlexPositions(statement);
  const data: IbkrResponse = {
    source: "flex",
    asOf: new Date().toISOString(),
    summary: parseFlexSummary(statement, positions),
    positions,
  };

  cache = { data, expiresAt: Date.now() + cacheMs() };
  return data;
}

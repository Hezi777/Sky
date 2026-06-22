// Israeli mutual fund (קרן נאמנות) price lookup by fund number.
//
// Source: Maya / TASE undocumented JSON API (the same backend maya.tase.co.il uses).
//   GET https://mayaapi.tase.co.il/api/fund/details?fundId=<num>
//   Requires the header `X-Maya-With: allow` plus a browser-like referer/UA,
//   otherwise the edge returns 403/empty. This is scrape-grade and undocumented —
//   TASE can change or block it at any time, so getFairPrice() returns null
//   (never throws) and the widget falls back to a manual price.
//
// PRICE SCALE: we return Maya's quoted UnitValuePrice as-is (e.g. 103.75). This
// is the same scale brokerage statements use to report unit counts (units =
// amount / unit price), so valuation (units * price) stays internally consistent
// with the contributions the user enters. Do NOT divide by 100 here — doing so
// caused a 100x mismatch against statement-derived units. The manual-price
// override covers any fund Maya quotes on a different scale.

const MAYA_BASE_URL = "https://mayaapi.tase.co.il/api/fund/details";

const MAYA_HEADERS: Record<string, string> = {
  "X-Maya-With": "allow",
  "Accept-Language": "en-US",
  Accept: "application/json, text/plain, */*",
  referer: "https://maya.tase.co.il/",
  "User-Agent":
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36",
};

export interface FairPriceResult {
  price: number; // quoted unit price (Maya scale, used as-is)
  asOf: string; // ISO date the price is valid for
  currency: string; // "ILS"
  source: string; // human-readable source label
  fundName?: string; // fund long name if available
}

interface MayaFundDetails {
  UnitValuePrice?: number;
  PurchasePrice?: number;
  SellPrice?: number;
  CreationPrice?: number;
  UnitValueValidDate?: string;
  RelevantDate?: string;
  CorrectTradeDate?: string;
  FundLongName?: string;
  FundShortName?: string;
}

function firstNumber(...vals: Array<unknown>): number | null {
  for (const v of vals) {
    if (typeof v === "number" && Number.isFinite(v) && v > 0) return v;
  }
  return null;
}

function firstString(...vals: Array<unknown>): string | null {
  for (const v of vals) {
    if (typeof v === "string" && v.trim().length > 0) return v;
  }
  return null;
}

/**
 * Fetch the latest unit price/NAV for an Israeli mutual fund by fund number.
 * Returns null (does not throw) when the source is unavailable or unparseable.
 */
export async function getFairPrice(
  fundNumber: string,
): Promise<FairPriceResult | null> {
  const id = String(fundNumber).trim();
  if (!/^\d+$/.test(id)) return null;

  let json: MayaFundDetails;
  try {
    const res = await fetch(`${MAYA_BASE_URL}?fundId=${encodeURIComponent(id)}`, {
      headers: MAYA_HEADERS,
      // No caching — always live-fetched per app rules.
      cache: "no-store",
    });
    if (!res.ok) return null;
    json = (await res.json()) as MayaFundDetails;
  } catch {
    return null;
  }

  if (!json || typeof json !== "object") return null;

  // Prefer the official unit value; fall back to purchase/creation/sell prices.
  // Returned as-is (see PRICE SCALE note in the file header).
  const price = firstNumber(
    json.UnitValuePrice,
    json.PurchasePrice,
    json.CreationPrice,
    json.SellPrice,
  );
  if (price === null) return null;

  const asOfRaw = firstString(
    json.UnitValueValidDate,
    json.RelevantDate,
    json.CorrectTradeDate,
  );
  const asOf = asOfRaw ? asOfRaw.split("T")[0] : new Date().toISOString().split("T")[0];

  const fundName = firstString(json.FundLongName, json.FundShortName) ?? undefined;

  return {
    price,
    asOf,
    currency: "ILS",
    source: "Maya / TASE",
    fundName,
  };
}

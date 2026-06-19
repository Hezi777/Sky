import { NextResponse } from "next/server";

export const dynamic = "force-dynamic";

interface FinnhubQuote {
  c: number; // current price
  d: number; // change
  dp: number; // percent change
}

interface StockQuote {
  symbol: string;
  price: number;
  changePercent: number;
  change: number;
}

export async function GET(request: Request) {
  const apiKey = process.env.FINNHUB_API_KEY;
  if (!apiKey) {
    return NextResponse.json({ error: "Finnhub key not set" }, { status: 200 });
  }

  const { searchParams } = new URL(request.url);
  const symbols = (searchParams.get("symbols") ?? "")
    .split(",")
    .map((s) => s.trim().toUpperCase())
    .filter(Boolean);

  if (symbols.length === 0) {
    return NextResponse.json([] as StockQuote[]);
  }

  try {
    const quotes = await Promise.all(
      symbols.map(async (symbol): Promise<StockQuote> => {
        const res = await fetch(
          `https://finnhub.io/api/v1/quote?symbol=${encodeURIComponent(
            symbol
          )}&token=${apiKey}`,
          { cache: "no-store" }
        );
        if (!res.ok) throw new Error(`Finnhub ${res.status} for ${symbol}`);
        const data = (await res.json()) as FinnhubQuote;
        return {
          symbol,
          price: data.c ?? 0,
          changePercent: data.dp ?? 0,
          change: data.d ?? 0,
        };
      })
    );

    return NextResponse.json(quotes);
  } catch (err) {
    const message = err instanceof Error ? err.message : "Unknown error";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}

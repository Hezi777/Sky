"use client";

import {
  AlertCircle,
  Plus,
  Settings2,
  TrendingDown,
  TrendingUp,
  Trash2,
  X,
} from "lucide-react";
import { useEffect, useMemo, useState } from "react";
import useSWR from "swr";

import { AnimatedNumber } from "@/components/animated-number";
import { BrandLogo } from "@/components/brand-logo";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { fetcher } from "@/lib/fetcher";
import type { FairConfig, FairContribution, FairPrice } from "@/lib/types";

const STORAGE_KEY = "sky:fair";

const DEFAULT_CONFIG: FairConfig = {
  fundNumber: "5140785",
  fundName: "Meitav",
  contributions: [],
};

function loadConfig(): FairConfig {
  if (typeof window === "undefined") return DEFAULT_CONFIG;
  try {
    const raw = window.localStorage.getItem(STORAGE_KEY);
    if (!raw) return DEFAULT_CONFIG;
    const parsed = JSON.parse(raw) as Partial<FairConfig>;
    return {
      fundNumber: parsed.fundNumber ?? DEFAULT_CONFIG.fundNumber,
      fundName: parsed.fundName ?? DEFAULT_CONFIG.fundName,
      manualPrice:
        typeof parsed.manualPrice === "number" ? parsed.manualPrice : undefined,
      contributions: Array.isArray(parsed.contributions)
        ? parsed.contributions
        : [],
    };
  } catch {
    return DEFAULT_CONFIG;
  }
}

function fmtIls(n: number, decimals = 2) {
  return new Intl.NumberFormat(undefined, {
    style: "currency",
    currency: "ILS",
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals,
  }).format(n);
}

function fmtNum(n: number, decimals = 4) {
  return n.toLocaleString(undefined, {
    minimumFractionDigits: 0,
    maximumFractionDigits: decimals,
  });
}

function PnlValue({
  amount,
  percent,
}: {
  amount: number;
  percent: number;
}) {
  const positive = amount >= 0;
  const Icon = positive ? TrendingUp : TrendingDown;
  const cls = positive ? "text-emerald-500" : "text-red-500";
  return (
    <span className={`inline-flex items-center gap-1 font-medium ${cls}`}>
      <Icon className="h-4 w-4" />
      <AnimatedNumber
        value={amount}
        format={(value) => `${positive ? "+" : ""}${fmtIls(value)}`}
      />
      {" ("}
      <AnimatedNumber
        value={percent}
        format={(value) => `${positive ? "+" : ""}${value.toFixed(2)}%`}
      />
      {")"}
    </span>
  );
}

function FairSkeleton() {
  return (
    <Card className="flex h-full flex-col rounded-2xl">
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <BrandLogo name="fair" className="size-5 rounded" />
          Fair
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <Skeleton className="h-8 w-40" />
        <div className="flex gap-4">
          <Skeleton className="h-5 w-24" />
          <Skeleton className="h-5 w-24" />
        </div>
        <Skeleton className="h-28 w-full" />
      </CardContent>
    </Card>
  );
}

export function FairWidget() {
  // Start null on the server (and first client render) to avoid hydration
  // mismatch; hydrate from localStorage once mounted via mount flag below.
  const [config, setConfig] = useState<FairConfig | null>(null);
  const [editing, setEditing] = useState(false);
  const [adding, setAdding] = useState(false);

  // Read persisted config on mount (localStorage is client-only). Matches the
  // SSR-safe hydration pattern used by greeting-card.tsx.
  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setConfig(loadConfig());
  }, []);

  // Persist on change.
  useEffect(() => {
    if (!config || typeof window === "undefined") return;
    try {
      window.localStorage.setItem(STORAGE_KEY, JSON.stringify(config));
    } catch {
      /* ignore quota / private-mode errors */
    }
  }, [config]);

  const fundNumber = config?.fundNumber ?? "";
  const { data, error, isLoading } = useSWR<FairPrice>(
    fundNumber ? `/api/fair?fund=${fundNumber}` : null,
    fetcher,
    { revalidateOnFocus: false },
  );

  const livePrice = data && !error ? data : null;
  const manualPrice = config?.manualPrice;

  // Manual price wins when set; otherwise fall back to live; null if neither.
  const effectivePrice =
    typeof manualPrice === "number" ? manualPrice : (livePrice?.price ?? null);
  const priceMode: "manual" | "live" | "none" =
    typeof manualPrice === "number"
      ? "manual"
      : livePrice
        ? "live"
        : "none";

  const totals = useMemo(() => {
    const contribs = config?.contributions ?? [];
    const invested = contribs.reduce((s, c) => s + c.amount, 0);
    const units = contribs.reduce((s, c) => s + c.units, 0);
    const value = effectivePrice !== null ? units * effectivePrice : null;
    const gain = value !== null ? value - invested : null;
    const gainPct =
      gain !== null && invested > 0 ? (gain / invested) * 100 : null;
    return { invested, units, value, gain, gainPct };
  }, [config?.contributions, effectivePrice]);

  if (!config) return <FairSkeleton />;

  const hasContribs = config.contributions.length > 0;

  return (
    <Card className="flex h-full flex-col rounded-2xl">
      <CardHeader className="flex-row items-center justify-between space-y-0">
        <CardTitle className="flex items-center gap-2">
          <BrandLogo name="fair" className="size-5 rounded" />
          Fair
          <span className="text-sm font-normal text-muted-foreground">
            {config.fundName} · {config.fundNumber}
          </span>
        </CardTitle>
        <div className="flex items-center gap-1">
          <Button
            variant="ghost"
            size="icon-sm"
            aria-label={adding ? "Close add transaction" : "Add transaction"}
            onClick={() => {
              setEditing(false);
              setAdding((v) => !v);
            }}
          >
            {adding ? <X className="h-4 w-4" /> : <Plus className="h-4 w-4" />}
          </Button>
          <Button
            variant="ghost"
            size="icon-sm"
            aria-label={editing ? "Close settings" : "Fund settings"}
            onClick={() => {
              setAdding(false);
              setEditing((v) => !v);
            }}
          >
            {editing ? (
              <X className="h-4 w-4" />
            ) : (
              <Settings2 className="h-4 w-4" />
            )}
          </Button>
        </div>
      </CardHeader>

      <CardContent className="flex min-h-0 flex-1 flex-col space-y-4">
        {editing ? (
          <ConfigPanel config={config} setConfig={setConfig} />
        ) : adding ? (
          <AddTransactionForm
            setConfig={setConfig}
            onDone={() => setAdding(false)}
          />
        ) : (
          <>
            {hasContribs ? (
              <div className="space-y-1">
                {isLoading && priceMode === "none" ? (
                  <Skeleton className="h-9 w-40" />
                ) : (
                  <p className="text-3xl font-semibold tabular-nums">
                    {totals.value !== null ? (
                      <AnimatedNumber value={totals.value} format={fmtIls} />
                    ) : (
                      "—"
                    )}
                  </p>
                )}
                <div className="flex flex-wrap items-center gap-x-4 gap-y-1 text-sm">
                  <span className="text-muted-foreground">
                    Invested{" "}
                    <AnimatedNumber value={totals.invested} format={fmtIls} />
                  </span>
                  {totals.gain !== null && totals.gainPct !== null ? (
                    <PnlValue amount={totals.gain} percent={totals.gainPct} />
                  ) : null}
                </div>
              </div>
            ) : (
              <div className="rounded-2xl border border-dashed border-border bg-muted/25 p-4">
                <p className="text-base font-semibold">Start tracking Fair</p>
                <p className="mt-1 text-sm text-muted-foreground">
                  Add your first contribution. Values are stored locally in this browser.
                </p>
                <Button className="mt-4" size="sm" onClick={() => setAdding(true)}>
                  <Plus className="h-4 w-4" /> Add contribution
                </Button>
              </div>
            )}

            {/* Price line */}
            <div
              className={`flex flex-wrap items-center gap-2 text-xs text-muted-foreground ${
                hasContribs ? "" : "mt-auto"
              }`}
            >
              {priceMode === "none" ? (
                <span className="inline-flex items-center gap-1 text-red-500">
                  <AlertCircle className="h-3.5 w-3.5" />
                  No price — set a manual price in settings
                </span>
              ) : (
                <>
                  <span className="tabular-nums text-foreground">
                    <AnimatedNumber
                      value={effectivePrice ?? 0}
                      format={fmtIls}
                    />{" "}
                    / unit
                  </span>
                  <Badge
                    variant={priceMode === "manual" ? "secondary" : "outline"}
                  >
                    {priceMode === "manual" ? "manual" : "live"}
                  </Badge>
                  {priceMode === "live" && livePrice ? (
                    <span>
                      {livePrice.source} · as of {livePrice.asOf}
                    </span>
                  ) : null}
                  <span>
                    ·{" "}
                    <AnimatedNumber value={totals.units} format={fmtNum} />{" "}
                    units
                  </span>
                </>
              )}
            </div>

            {/* Contributions */}
            {hasContribs ? (
              <div className="min-h-0 flex-1 overflow-y-auto">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Date</TableHead>
                      <TableHead className="text-right">Amount</TableHead>
                      <TableHead className="text-right">Units</TableHead>
                      <TableHead className="w-8" />
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {config.contributions
                      .slice()
                      .sort((a, b) => (a.date < b.date ? 1 : -1))
                      .map((c) => (
                        <TableRow key={c.id}>
                          <TableCell className="font-medium">
                            {c.date}
                          </TableCell>
                          <TableCell className="text-right tabular-nums">
                            {fmtIls(c.amount)}
                          </TableCell>
                          <TableCell className="text-right tabular-nums">
                            {fmtNum(c.units)}
                          </TableCell>
                          <TableCell className="text-right">
                            <Button
                              variant="ghost"
                              size="icon-sm"
                              aria-label="Remove contribution"
                              onClick={() =>
                                setConfig((prev) =>
                                  prev
                                    ? {
                                        ...prev,
                                        contributions:
                                          prev.contributions.filter(
                                            (x) => x.id !== c.id,
                                          ),
                                      }
                                    : prev,
                                )
                              }
                            >
                              <Trash2 className="h-3.5 w-3.5 text-muted-foreground" />
                            </Button>
                          </TableCell>
                        </TableRow>
                      ))}
                  </TableBody>
                </Table>
              </div>
            ) : null}
          </>
        )}
      </CardContent>
    </Card>
  );
}

// --- Quick add-transaction form (the "+" button) ---------------------------

function AddTransactionForm({
  setConfig,
  onDone,
}: {
  setConfig: React.Dispatch<React.SetStateAction<FairConfig | null>>;
  onDone: () => void;
}) {
  const [date, setDate] = useState(new Date().toISOString().split("T")[0]);
  const [amount, setAmount] = useState("");
  const [units, setUnits] = useState("");
  const [buyPrice, setBuyPrice] = useState("");

  function addContribution() {
    const amt = parseFloat(amount);
    if (!Number.isFinite(amt) || amt <= 0 || !date) return;

    let u = parseFloat(units);
    if (!Number.isFinite(u) || u <= 0) {
      // Derive units from amount / buy price if units not given directly.
      const bp = parseFloat(buyPrice);
      if (Number.isFinite(bp) && bp > 0) {
        u = amt / bp;
      } else {
        return; // need either units or a buy price
      }
    }

    const entry: FairContribution = {
      id:
        typeof crypto !== "undefined" && crypto.randomUUID
          ? crypto.randomUUID()
          : `${Date.now()}-${Math.random().toString(36).slice(2)}`,
      date,
      amount: amt,
      units: u,
    };
    setConfig((prev) =>
      prev ? { ...prev, contributions: [...prev.contributions, entry] } : prev,
    );
    onDone();
  }

  return (
    <div className="space-y-2 overflow-y-auto">
      <p className="text-xs font-medium text-muted-foreground">
        Add transaction
      </p>
      <Input
        type="date"
        value={date}
        onChange={(e) => setDate(e.target.value)}
      />
      <Input
        placeholder="Amount invested ₪"
        inputMode="decimal"
        value={amount}
        onChange={(e) => setAmount(e.target.value)}
      />
      <div className="grid grid-cols-2 gap-2">
        <Input
          placeholder="Units bought"
          inputMode="decimal"
          value={units}
          onChange={(e) => setUnits(e.target.value)}
        />
        <Input
          placeholder="…or buy price ₪"
          inputMode="decimal"
          value={buyPrice}
          onChange={(e) => setBuyPrice(e.target.value)}
        />
      </div>
      <div className="flex items-center gap-2">
        <Button size="sm" onClick={addContribution}>
          <Plus className="h-4 w-4" /> Add
        </Button>
        <Button size="sm" variant="outline" onClick={onDone}>
          Cancel
        </Button>
      </div>
      <p className="text-[11px] text-muted-foreground">
        Enter units directly, or a buy price to compute units = amount ÷ price.
      </p>
    </div>
  );
}

// --- Fund settings panel (the gear button) ---------------------------------

function ConfigPanel({
  config,
  setConfig,
}: {
  config: FairConfig;
  setConfig: React.Dispatch<React.SetStateAction<FairConfig | null>>;
}) {
  const [fundNumber, setFundNumber] = useState(config.fundNumber);
  const [fundName, setFundName] = useState(config.fundName);
  const [manual, setManual] = useState(
    config.manualPrice !== undefined ? String(config.manualPrice) : "",
  );

  function saveFund() {
    const trimmedNum = fundNumber.trim();
    const num = /^\d+$/.test(trimmedNum) ? trimmedNum : config.fundNumber;
    const m = parseFloat(manual);
    setConfig((prev) =>
      prev
        ? {
            ...prev,
            fundNumber: num,
            fundName: fundName.trim() || prev.fundName,
            manualPrice: manual.trim() !== "" && m > 0 ? m : undefined,
          }
        : prev,
    );
  }

  function clearManual() {
    setManual("");
    setConfig((prev) => (prev ? { ...prev, manualPrice: undefined } : prev));
  }

  return (
    <div className="space-y-2 overflow-y-auto">
      <p className="text-xs font-medium text-muted-foreground">Fund</p>
      <div className="grid grid-cols-2 gap-2">
        <Input
          placeholder="Fund number"
          inputMode="numeric"
          value={fundNumber}
          onChange={(e) => setFundNumber(e.target.value)}
        />
        <Input
          placeholder="Fund name"
          value={fundName}
          onChange={(e) => setFundName(e.target.value)}
        />
      </div>
      <div className="flex items-center gap-2">
        <Input
          placeholder="Manual price ₪ (optional)"
          inputMode="decimal"
          value={manual}
          onChange={(e) => setManual(e.target.value)}
        />
        {config.manualPrice !== undefined ? (
          <Button variant="outline" size="sm" onClick={clearManual}>
            Clear
          </Button>
        ) : null}
      </div>
      <Button size="sm" onClick={saveFund}>
        Save fund
      </Button>
      <p className="text-[11px] text-muted-foreground">
        Set a manual price to override the live Maya/TASE price (used as fallback
        if the fetch fails).
      </p>
    </div>
  );
}

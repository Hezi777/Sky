"use client";

import { useEffect } from "react";
import { AlertCircle, TrendingDown, TrendingUp } from "lucide-react";
import { Cell, Pie, PieChart, Tooltip } from "recharts";
import useSWR from "swr";

import { AnimatedNumber } from "@/components/animated-number";
import { BrandLogo } from "@/components/brand-logo";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
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
import type { IbkrResponse } from "@/lib/types";

const CHART_COLORS = [
  "var(--chart-1, #5e6ad2)",
  "var(--chart-2, #4cc4a8)",
  "var(--chart-4, #f0b429)",
  "var(--chart-3, #a87ff0)",
  "var(--chart-5, #f76d7e)",
];

function fmt(n: number, decimals = 2) {
  return n.toLocaleString(undefined, {
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals,
  });
}

function fmtUsd(n: number, decimals = 0) {
  return new Intl.NumberFormat(undefined, {
    style: "currency",
    currency: "USD",
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals,
  }).format(n);
}

function Metric({
  label,
  value,
  suffix = "",
  money = false,
}: {
  label: string;
  value: number | null;
  suffix?: string;
  money?: boolean;
}) {
  if (value === null) {
    return (
      <div className="min-w-28">
        <span className="text-xs text-muted-foreground">{label}</span>
        <p className="mt-0.5 text-sm font-medium text-muted-foreground">Unavailable</p>
      </div>
    );
  }

  const positive = value >= 0;
  const Icon = positive ? TrendingUp : TrendingDown;
  const formatValue = (latest: number) =>
    money
      ? `${positive ? "+" : ""}${fmtUsd(latest, 2)}`
      : `${positive ? "+" : ""}${fmt(latest)}${suffix}`;

  return (
    <div className="min-w-28">
      <span className="text-xs text-muted-foreground">{label}</span>
      <p
        className={`mt-0.5 inline-flex items-center gap-1 text-sm font-medium ${
          positive ? "text-emerald-500" : "text-red-500"
        }`}
      >
        <Icon className="h-3.5 w-3.5" />
        <AnimatedNumber value={value} format={formatValue} />
      </p>
    </div>
  );
}

function IBKRSkeleton() {
  return (
    <Card className="flex h-full flex-col rounded-2xl">
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <BrandLogo name="ibkr" className="h-5 w-auto" />
          IBKR Portfolio
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <Skeleton className="h-9 w-44" />
        <div className="flex gap-4">
          <Skeleton className="h-10 w-32" />
          <Skeleton className="h-10 w-32" />
        </div>
        <Skeleton className="h-44 w-full" />
      </CardContent>
    </Card>
  );
}

export function IBKRWidget() {
  const { data, error, isLoading } = useSWR<IbkrResponse>("/api/ibkr", fetcher);

  useEffect(() => {
    let cancelled = false;

    async function ping() {
      if (cancelled || document.hidden) return;
      await fetch("/api/ibkr/keepalive", { method: "POST" }).catch(() => {});
    }

    void ping();
    const id = window.setInterval(() => void ping(), 60_000);
    return () => {
      cancelled = true;
      window.clearInterval(id);
    };
  }, []);

  if (isLoading) return <IBKRSkeleton />;

  const apiError = (data as unknown as { error?: string })?.error;
  if (error || apiError) {
    return (
      <Card className="flex h-full flex-col rounded-2xl">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <BrandLogo name="ibkr" className="h-5 w-auto" />
            IBKR Portfolio
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex items-center gap-2 text-sm text-muted-foreground">
            <AlertCircle className="h-4 w-4 shrink-0 text-red-500" />
            <span>{apiError ?? error?.message ?? "Failed to load portfolio"}</span>
          </div>
        </CardContent>
      </Card>
    );
  }

  if (!data) return <IBKRSkeleton />;

  const { summary, positions } = data;
  const sorted = [...positions].sort((a, b) => b.marketValue - a.marketValue);
  const top = sorted.slice(0, 5);
  const rest = sorted.slice(5);
  const donutData = [
    ...top.map((p) => ({ name: p.ticker, value: Math.abs(p.marketValue) })),
    ...(rest.length > 0
      ? [{ name: "Other", value: rest.reduce((s, p) => s + Math.abs(p.marketValue), 0) }]
      : []),
  ];
  const totalMv = donutData.reduce((s, d) => s + d.value, 0);

  return (
    <Card className="flex h-full flex-col rounded-2xl">
      <CardHeader className="pb-2">
        <CardTitle className="flex items-center gap-2">
          <BrandLogo name="ibkr" className="h-5 w-auto" />
          IBKR Portfolio
        </CardTitle>
      </CardHeader>

      <CardContent className="flex min-h-0 min-w-0 flex-1 flex-col gap-5">
        <div className="space-y-2">
          <p className="text-3xl font-semibold tracking-tight tabular-nums sm:text-4xl">
            <AnimatedNumber value={summary.totalValue} format={(value) => fmtUsd(value)} />
          </p>
          <div className="flex flex-wrap gap-4">
            <Metric label="Unrealized" value={summary.unrealizedPnl} money />
            <Metric label="Return" value={summary.unrealizedPnlPercent} suffix="%" />
            <Metric label="Day P&L" value={summary.dayPnl} money />
          </div>
        </div>

        {donutData.length > 0 && (
          <div className="grid min-w-0 gap-4 lg:grid-cols-[220px_1fr]">
            <div className="flex h-44 min-h-44 min-w-0 items-center justify-center">
              <PieChart width={220} height={176}>
                <Pie
                  data={donutData}
                  cx="50%"
                  cy="50%"
                  innerRadius={54}
                  outerRadius={76}
                  paddingAngle={3}
                  dataKey="value"
                  stroke="var(--card)"
                  strokeWidth={3}
                >
                  {donutData.map((_, i) => (
                    <Cell key={i} fill={CHART_COLORS[i % CHART_COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip formatter={(value) => [fmtUsd(Number(value)), "Value"]} />
              </PieChart>
            </div>

            <div className="min-w-0 space-y-2 self-center">
              <p className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">
                Allocation
              </p>
              {donutData.map((item, i) => (
                <div key={item.name} className="flex items-center gap-2 text-sm">
                  <span
                    className="h-2.5 w-2.5 shrink-0 rounded-full"
                    style={{ backgroundColor: CHART_COLORS[i % CHART_COLORS.length] }}
                  />
                  <span className="min-w-0 flex-1 truncate font-medium">{item.name}</span>
                  <span className="text-muted-foreground tabular-nums">
                    {totalMv > 0 ? ((item.value / totalMv) * 100).toFixed(1) : "0.0"}%
                  </span>
                  <span className="w-20 text-right tabular-nums">
                    <AnimatedNumber value={item.value} format={(value) => fmtUsd(value)} />
                  </span>
                </div>
              ))}
            </div>
          </div>
        )}

        {positions.length > 0 && (
          <div className="min-h-0 overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Ticker</TableHead>
                  <TableHead className="text-right">Shares</TableHead>
                  <TableHead className="text-right">Avg</TableHead>
                  <TableHead className="text-right">Price</TableHead>
                  <TableHead className="text-right">P&L</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {positions.map((pos) => (
                  <TableRow key={pos.ticker}>
                    <TableCell className="font-medium">{pos.ticker}</TableCell>
                    <TableCell className="text-right tabular-nums">{fmt(pos.shares, 2)}</TableCell>
                    <TableCell className="text-right tabular-nums">{fmtUsd(pos.avgCost, 2)}</TableCell>
                    <TableCell className="text-right tabular-nums">{fmtUsd(pos.currentPrice, 2)}</TableCell>
                    <TableCell
                      className={`text-right tabular-nums font-medium ${
                        pos.pnlPercent >= 0 ? "text-emerald-500" : "text-red-500"
                      }`}
                    >
                      {pos.pnlPercent >= 0 ? "+" : ""}
                      {fmt(pos.pnlPercent)}%
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}
      </CardContent>
    </Card>
  );
}

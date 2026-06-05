"use client";

import { AlertCircle, TrendingDown, TrendingUp } from "lucide-react";
import { Cell, Legend, Pie, PieChart, ResponsiveContainer, Tooltip } from "recharts";
import useSWR from "swr";

import { BrandLogo } from "@/components/brand-logo";
import {
  Card,
  CardContent,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
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

// Chart colours that respect the CSS custom property tokens defined by shadcn
const CHART_COLORS = [
  "var(--chart-1, #6366f1)",
  "var(--chart-2, #22d3ee)",
  "var(--chart-3, #f59e0b)",
  "var(--chart-4, #10b981)",
  "var(--chart-5, #f43f5e)",
];

function fmt(n: number, decimals = 2) {
  return n.toLocaleString(undefined, {
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals,
  });
}

function fmtUsd(n: number) {
  return new Intl.NumberFormat(undefined, {
    style: "currency",
    currency: "USD",
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(n);
}

function PnlBadge({ value, suffix = "" }: { value: number; suffix?: string }) {
  const positive = value >= 0;
  const Icon = positive ? TrendingUp : TrendingDown;
  return (
    <span
      className={`inline-flex items-center gap-1 text-sm font-medium ${
        positive ? "text-emerald-500" : "text-red-500"
      }`}
    >
      <Icon className="h-4 w-4" />
      {positive ? "+" : ""}
      {fmt(value)}
      {suffix}
    </span>
  );
}

function IBKRSkeleton() {
  return (
    <Card className="flex h-full flex-col rounded-2xl">
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <BrandLogo name="ibkr" className="h-4 w-auto max-w-[96px]" />
          Portfolio
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <Skeleton className="h-8 w-40" />
        <div className="flex gap-4">
          <Skeleton className="h-5 w-28" />
          <Skeleton className="h-5 w-28" />
        </div>
        <Skeleton className="h-48 w-full" />
        <Skeleton className="h-32 w-full" />
      </CardContent>
      <CardFooter>
        <Skeleton className="h-4 w-64" />
      </CardFooter>
    </Card>
  );
}

export function IBKRWidget() {
  const { data, error, isLoading } = useSWR<IbkrResponse>("/api/ibkr", fetcher);

  if (isLoading) return <IBKRSkeleton />;

  // API returned an error shape or SWR threw
  const apiError = (data as unknown as { error?: string })?.error;
  if (error || apiError) {
    return (
      <Card className="flex h-full flex-col rounded-2xl">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
          <BrandLogo name="ibkr" className="h-4 w-auto max-w-[96px]" />
          Portfolio
        </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex items-center gap-2 text-sm text-muted-foreground">
            <AlertCircle className="h-4 w-4 shrink-0 text-red-500" />
            <span>{apiError ?? error?.message ?? "Failed to load portfolio"}</span>
          </div>
        </CardContent>
        <CardFooter>
          <p className="text-xs text-muted-foreground">
            Connect Interactive Brokers via SnapTrade — see scripts/snaptrade-setup.ts
          </p>
        </CardFooter>
      </Card>
    );
  }

  if (!data) return <IBKRSkeleton />;

  const { summary, positions } = data;

  // Build donut data — use up to 5 slices; group the rest as "Other"
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
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <BrandLogo name="ibkr" className="h-4 w-auto max-w-[96px]" />
          Portfolio
        </CardTitle>
      </CardHeader>

      <CardContent className="flex min-h-0 flex-1 flex-col space-y-5">
        {/* Summary row */}
        <div className="space-y-1">
          <p className="text-3xl font-semibold tabular-nums">
            {fmtUsd(summary.totalValue)}
          </p>
          <div className="flex flex-wrap items-center gap-4">
            <div className="flex flex-col">
              <span className="text-xs text-muted-foreground">Day P&amp;L</span>
              <PnlBadge value={summary.dayPnl} />
            </div>
            <div className="flex flex-col">
              <span className="text-xs text-muted-foreground">Unrealized P&amp;L</span>
              <PnlBadge value={summary.unrealizedPnlPercent} suffix="%" />
            </div>
          </div>
        </div>

        {/* Allocation donut */}
        {donutData.length > 0 && (
          <div className="h-52 w-full">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={donutData}
                  cx="50%"
                  cy="50%"
                  innerRadius="55%"
                  outerRadius="80%"
                  paddingAngle={2}
                  dataKey="value"
                  label={({ name, value }) =>
                    `${name} ${totalMv > 0 ? ((value / totalMv) * 100).toFixed(1) : 0}%`
                  }
                  labelLine={false}
                >
                  {donutData.map((_, i) => (
                    <Cell
                      key={i}
                      fill={CHART_COLORS[i % CHART_COLORS.length]}
                    />
                  ))}
                </Pie>
                <Tooltip
                  formatter={(value) => [fmtUsd(Number(value)), "Market Value"]}
                />
                <Legend
                  iconType="circle"
                  iconSize={8}
                  wrapperStyle={{ fontSize: "12px" }}
                />
              </PieChart>
            </ResponsiveContainer>
          </div>
        )}

        {/* Positions table */}
        {positions.length > 0 && (
          <div className="min-h-0 flex-1 overflow-y-auto">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Ticker</TableHead>
                <TableHead className="text-right">Shares</TableHead>
                <TableHead className="text-right">Avg Cost</TableHead>
                <TableHead className="text-right">Price</TableHead>
                <TableHead className="text-right">P&amp;L %</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {positions.map((pos) => (
                <TableRow key={pos.ticker}>
                  <TableCell className="font-medium">{pos.ticker}</TableCell>
                  <TableCell className="text-right tabular-nums">
                    {fmt(pos.shares, 0)}
                  </TableCell>
                  <TableCell className="text-right tabular-nums">
                    ${fmt(pos.avgCost)}
                  </TableCell>
                  <TableCell className="text-right tabular-nums">
                    ${fmt(pos.currentPrice)}
                  </TableCell>
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

      <CardFooter>
        <p className="text-xs text-muted-foreground">
          Connect Interactive Brokers via SnapTrade — see scripts/snaptrade-setup.ts
        </p>
      </CardFooter>
    </Card>
  );
}

"use client";

import useSWR from "swr";
import { SiGithub } from "react-icons/si";

import { fetcher } from "@/lib/fetcher";
import type { GithubContributionDay, GithubResponse } from "@/lib/types";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";

// GitHub's standard light-mode contribution scale
const LEVEL_COLORS: Record<0 | 1 | 2 | 3 | 4, string> = {
  0: "#ebedf0",
  1: "#9be9a8",
  2: "#40c463",
  3: "#30a14e",
  4: "#216e39",
};

const CELL = 11; // px per cell
const GAP = 2;  // px gap between cells
const STEP = CELL + GAP;

function HeatmapSvg({ contributions }: { contributions: GithubContributionDay[] }) {
  // Pad so the array starts on a Sunday (day index 0).
  const firstDate = contributions[0]?.date;
  const startDow = firstDate ? new Date(firstDate + "T00:00:00").getDay() : 0;
  const padded: (GithubContributionDay | null)[] = [
    ...Array.from({ length: startDow }, () => null),
    ...contributions,
  ];

  // Split into columns of 7 (one column per week).
  const cols: (GithubContributionDay | null)[][] = [];
  for (let i = 0; i < padded.length; i += 7) {
    cols.push(padded.slice(i, i + 7));
  }

  const svgWidth = cols.length * STEP;
  const svgHeight = 7 * STEP - GAP;

  return (
    <svg
      width={svgWidth}
      height={svgHeight}
      aria-label="Contribution heatmap"
      className="overflow-visible"
    >
      {cols.map((col, ci) =>
        col.map((day, ri) => {
          if (!day) return null;
          const x = ci * STEP;
          const y = ri * STEP;
          return (
            <rect
              key={day.date}
              x={x}
              y={y}
              width={CELL}
              height={CELL}
              rx={2}
              ry={2}
              fill={LEVEL_COLORS[day.level]}
            >
              <title>
                {day.count} contribution{day.count !== 1 ? "s" : ""} on {day.date}
              </title>
            </rect>
          );
        })
      )}
    </svg>
  );
}

export function GithubHeatmap() {
  const { data, error, isLoading } = useSWR<GithubResponse>(
    "/api/github",
    fetcher
  );

  return (
    <Card className="flex h-full flex-col rounded-2xl">
      <CardHeader className="border-b">
        <CardTitle className="flex items-center gap-2">
          <SiGithub className="size-4" />
          Contributions
          {data && (
            <span className="ml-auto text-sm font-normal text-muted-foreground">
              {data.totalContributions.toLocaleString()} this year
            </span>
          )}
        </CardTitle>
      </CardHeader>
      <CardContent className="pt-3">
        {isLoading && <Skeleton className="h-[106px] w-full" />}

        {error && (
          <div className="flex items-center gap-2 text-sm text-muted-foreground">
            <SiGithub className="size-4 shrink-0" />
            <span>Could not load contributions</span>
          </div>
        )}

        {data && (
          <div className="overflow-x-auto">
            <HeatmapSvg contributions={data.contributions} />
          </div>
        )}
      </CardContent>
    </Card>
  );
}

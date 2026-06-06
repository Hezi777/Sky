"use client";

import { Star } from "lucide-react";
import useSWR from "swr";

import { BrandLogo } from "@/components/brand-logo";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { GitHubCalendar } from "@/components/ui/git-hub-calendar";
import { Skeleton } from "@/components/ui/skeleton";
import { fetcher } from "@/lib/fetcher";
import type { GithubRepo, GithubResponse } from "@/lib/types";

const GITHUB_COLORS = [
  "var(--github-0)",
  "var(--github-1)",
  "var(--github-2)",
  "var(--github-3)",
  "var(--github-4)",
];

function relativeTime(isoDate: string): string {
  const diffMs = Date.now() - new Date(isoDate).getTime();
  const diffSec = Math.floor(diffMs / 1000);
  if (diffSec < 60) return "just now";
  const diffMin = Math.floor(diffSec / 60);
  if (diffMin < 60) return `${diffMin}m ago`;
  const diffHr = Math.floor(diffMin / 60);
  if (diffHr < 24) return `${diffHr}h ago`;
  const diffDay = Math.floor(diffHr / 24);
  if (diffDay < 30) return `${diffDay}d ago`;
  const diffMo = Math.floor(diffDay / 30);
  if (diffMo < 12) return `${diffMo}mo ago`;
  return `${Math.floor(diffMo / 12)}y ago`;
}

function RepoRow({ repo }: { repo: GithubRepo }) {
  return (
    <a
      href={repo.url}
      target="_blank"
      rel="noopener noreferrer"
      className="group flex min-h-0 flex-1 flex-col justify-center rounded-xl border border-border/70 bg-muted/20 px-3 py-2 transition-colors hover:bg-muted/55"
    >
      <div className="flex items-center gap-2">
        <p className="min-w-0 flex-1 truncate text-sm font-medium text-foreground group-hover:text-primary">
          {repo.name}
        </p>
        <span className="inline-flex items-center gap-1 text-xs text-muted-foreground">
          <Star className="size-3" />
          {repo.stars}
        </span>
      </div>
      <div className="mt-1 flex items-center justify-between gap-2 text-xs text-muted-foreground/75">
        <span className="truncate">{repo.language ?? "Code"}</span>
        <span className="shrink-0">pushed {relativeTime(repo.pushedAt)}</span>
      </div>
    </a>
  );
}

export function GithubHeatmap() {
  const { data, error, isLoading } = useSWR<GithubResponse>("/api/github", fetcher);

  return (
    <Card className="flex h-full flex-col rounded-2xl">
      <CardHeader className="border-b border-border/70 pb-3">
        <CardTitle className="flex items-center gap-2">
          <BrandLogo name="github" className="size-4" />
          GitHub Activity
          {data && (
            <span className="ml-auto text-sm font-normal text-muted-foreground">
              {data.totalContributions.toLocaleString()} contributions
            </span>
          )}
        </CardTitle>
      </CardHeader>

      <CardContent className="grid items-stretch gap-5 pt-4 xl:grid-cols-[minmax(0,1fr)_17rem]">
        {isLoading && (
          <>
            <Skeleton className="h-[150px] w-full" />
            <div className="space-y-2">
              <Skeleton className="h-20 w-full" />
              <Skeleton className="h-20 w-full" />
            </div>
          </>
        )}

        {error && (
          <div className="flex items-center gap-2 text-sm text-muted-foreground xl:col-span-2">
            <BrandLogo name="github" className="size-4 shrink-0" />
            <span>Could not load GitHub activity</span>
          </div>
        )}

        {data && (
          <>
            <div className="min-w-0 rounded-2xl bg-muted/10 px-2 py-3 xl:min-h-[11.25rem]">
              <GitHubCalendar
                data={data.contributions}
                colors={GITHUB_COLORS}
                density="spacious"
              />
            </div>
            <div className="flex min-h-0 flex-col gap-2">
              <div className="flex items-center justify-between gap-2">
                <p className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">
                  Recent repos
                </p>
                {data.repos.length > 3 && (
                  <span className="text-xs text-muted-foreground/70">
                    latest 3
                  </span>
                )}
              </div>
              <div className="flex min-h-0 flex-1 flex-col gap-2">
                {data.repos.slice(0, 3).map((repo) => (
                  <RepoRow key={repo.name} repo={repo} />
                ))}
              </div>
            </div>
          </>
        )}
      </CardContent>
    </Card>
  );
}

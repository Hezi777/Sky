"use client";

import useSWR from "swr";
import { Star } from "lucide-react";
import { SiGithub } from "react-icons/si";

import { fetcher } from "@/lib/fetcher";
import type { GithubResponse } from "@/lib/types";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";

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

function truncate(text: string, max: number): string {
  return text.length <= max ? text : text.slice(0, max - 1) + "…";
}

export function GithubRepos() {
  const { data, error, isLoading } = useSWR<GithubResponse>(
    "/api/github",
    fetcher
  );

  return (
    <Card className="flex h-full flex-col rounded-2xl">
      <CardHeader className="border-b">
        <CardTitle className="flex items-center gap-2">
          <SiGithub className="size-4" />
          GitHub
        </CardTitle>
      </CardHeader>
      <CardContent className="pt-3">
        {isLoading && (
          <div className="space-y-3">
            {Array.from({ length: 4 }).map((_, i) => (
              <div key={i} className="space-y-1.5">
                <Skeleton className="h-4 w-1/3" />
                <Skeleton className="h-3 w-2/3" />
              </div>
            ))}
          </div>
        )}

        {error && (
          <div className="flex items-center gap-2 text-sm text-muted-foreground">
            <SiGithub className="size-4 shrink-0" />
            <span>Could not load repos</span>
          </div>
        )}

        {data && (
          <ul className="space-y-3">
            {data.repos.map((repo) => (
              <li key={repo.name}>
                <a
                  href={repo.url}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="group block space-y-1"
                >
                  <div className="flex items-center gap-2">
                    <span className="text-sm font-medium text-primary group-hover:underline">
                      {repo.name}
                    </span>
                    {repo.language && (
                      <Badge variant="secondary" className="text-xs">
                        {repo.language}
                      </Badge>
                    )}
                    <span className="ml-auto flex items-center gap-1 text-xs text-muted-foreground">
                      <Star className="size-3" />
                      {repo.stars}
                    </span>
                  </div>
                  {repo.description && (
                    <p className="text-xs text-muted-foreground">
                      {truncate(repo.description, 60)}
                    </p>
                  )}
                  <p className="text-xs text-muted-foreground/60">
                    pushed {relativeTime(repo.pushedAt)}
                  </p>
                </a>
              </li>
            ))}
          </ul>
        )}
      </CardContent>
    </Card>
  );
}

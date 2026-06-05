"use client";

import useSWR from "swr";
import { SiNotion } from "react-icons/si";
import { AlertCircle } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { fetcher } from "@/lib/fetcher";
import type { NotionProject } from "@/lib/types";

function ProjectSkeleton() {
  return (
    <div className="space-y-1.5">
      <Skeleton className="h-4 w-3/4" />
      <Skeleton className="h-3 w-1/2" />
      <Skeleton className="h-3 w-2/3" />
    </div>
  );
}

export function ActiveProjects() {
  const { data, error, isLoading } = useSWR<NotionProject[]>(
    "/api/notion/projects",
    fetcher
  );

  return (
    <Card className="flex h-full flex-col rounded-2xl">
      <CardHeader className="flex flex-row items-center gap-2 pb-3">
        <SiNotion className="h-4 w-4 shrink-0 text-muted-foreground" />
        <CardTitle className="text-sm font-semibold">Active Projects</CardTitle>
      </CardHeader>

      <CardContent className="space-y-4">
        {isLoading && (
          <>
            <ProjectSkeleton />
            <ProjectSkeleton />
            <ProjectSkeleton />
          </>
        )}

        {error && (
          <div className="flex items-center gap-2 text-sm text-destructive">
            <AlertCircle className="h-4 w-4 shrink-0" />
            <span>{error.message ?? "Failed to load projects"}</span>
          </div>
        )}

        {data && data.length === 0 && (
          <p className="text-sm text-muted-foreground">No active projects.</p>
        )}

        {data &&
          data.map((project) => (
            <div key={project.id} className="space-y-1">
              <p className="text-sm font-semibold leading-snug">{project.name}</p>

              <div className="flex flex-wrap gap-1">
                {project.stage && (
                  <Badge variant="secondary" className="text-xs">
                    {project.stage}
                  </Badge>
                )}
                {project.type && (
                  <Badge variant="outline" className="text-xs">
                    {project.type}
                  </Badge>
                )}
              </div>

              {project.stack && (
                <p className="text-xs text-muted-foreground">{project.stack}</p>
              )}

              {project.nextAction && (
                <p className="text-xs text-muted-foreground">
                  → {project.nextAction}
                </p>
              )}
            </div>
          ))}

        <a
          href="https://notion.so"
          target="_blank"
          rel="noopener noreferrer"
          className="block pt-1 text-xs text-muted-foreground underline-offset-2 hover:underline"
        >
          See all in Notion
        </a>
      </CardContent>
    </Card>
  );
}

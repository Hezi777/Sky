"use client";

import useSWR from "swr";
import { SiNotion } from "react-icons/si";
import { AlertCircle } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { fetcher } from "@/lib/fetcher";
import type { NotionNextTask } from "@/lib/types";

export function NextTask() {
  const { data, error, isLoading } = useSWR<NotionNextTask | null>(
    "/api/notion/nexttask",
    fetcher
  );

  return (
    <Card className="flex h-full flex-col rounded-2xl">
      <CardHeader className="flex flex-row items-center gap-2 pb-3">
        <SiNotion className="h-4 w-4 shrink-0 text-muted-foreground" />
        <CardTitle className="text-sm font-semibold">Next Task</CardTitle>
      </CardHeader>

      <CardContent>
        {isLoading && (
          <div className="space-y-2">
            <Skeleton className="h-6 w-5/6" />
            <Skeleton className="h-4 w-1/2" />
            <Skeleton className="h-3 w-1/3" />
          </div>
        )}

        {error && (
          <div className="flex items-center gap-2 text-sm text-destructive">
            <AlertCircle className="h-4 w-4 shrink-0" />
            <span>{error.message ?? "Failed to load next task"}</span>
          </div>
        )}

        {!isLoading && !error && data === null && (
          <p className="text-sm text-muted-foreground">Nothing in progress.</p>
        )}

        {data && (
          <div className="space-y-2">
            {data.nextAction ? (
              <p className="text-base font-semibold leading-snug">
                {data.nextAction}
              </p>
            ) : (
              <p className="text-base font-semibold leading-snug text-muted-foreground">
                No next action set
              </p>
            )}

            <p className="text-sm text-muted-foreground">{data.name}</p>

            <div className="flex flex-wrap gap-1">
              {data.stage && (
                <Badge variant="secondary" className="text-xs">
                  {data.stage}
                </Badge>
              )}
              {data.type && (
                <Badge variant="outline" className="text-xs">
                  {data.type}
                </Badge>
              )}
            </div>
          </div>
        )}
      </CardContent>
    </Card>
  );
}

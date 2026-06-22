"use client";

import { useState } from "react";
import { Link, Loader2, Plus } from "lucide-react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import type { ResourceProperties } from "@/lib/types";

export function ResourceQuickAdd() {
  const [url, setUrl] = useState("");
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!url.trim()) return;

    setLoading(true);
    try {
      const res = await fetch("/api/ai/resource", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ url: url.trim() }),
      });

      const data: ResourceProperties & { error?: string } = await res.json();

      if (!res.ok || data.error) {
        toast.error(data.error ?? "Failed to save resource");
      } else {
        toast.success("Added to Notion Resources");
        setUrl("");
      }
    } catch {
      toast.error("Network error");
    } finally {
      setLoading(false);
    }
  }

  return (
    <Card className="flex h-full flex-col rounded-2xl">
      <CardHeader>
        <CardTitle className="flex items-center gap-2 text-sm font-medium">
          <Link className="size-4 text-muted-foreground" />
          Save Resource
        </CardTitle>
      </CardHeader>
      <CardContent className="flex flex-1 flex-col justify-between gap-4">
        <p className="text-sm leading-6 text-muted-foreground">
          Drop a useful link here and Sky will classify it into your Notion
          resources.
        </p>
        <form onSubmit={handleSubmit} className="flex gap-2">
          <Input
            type="url"
            placeholder="Paste a URL…"
            value={url}
            onChange={(e) => setUrl(e.target.value)}
            disabled={loading}
            className="flex-1"
          />
          <Button type="submit" disabled={loading || !url.trim()} size="default" className="transition-all duration-200">
            {loading ? (
              <Loader2 className="size-4 animate-spin" />
            ) : (
              <Plus className="size-4 transition-transform duration-200 group-hover:rotate-90" />
            )}
            <span className="sr-only">Add</span>
          </Button>
        </form>
      </CardContent>
    </Card>
  );
}

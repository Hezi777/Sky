"use client";

import { useState } from "react";
import { Link, Plus } from "lucide-react";
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
      <CardContent>
        <form onSubmit={handleSubmit} className="flex gap-2">
          <Input
            type="url"
            placeholder="Paste a URL…"
            value={url}
            onChange={(e) => setUrl(e.target.value)}
            disabled={loading}
            className="flex-1"
          />
          <Button type="submit" disabled={loading || !url.trim()} size="default">
            <Plus className="size-4" />
            <span className="sr-only">Add</span>
          </Button>
        </form>
      </CardContent>
    </Card>
  );
}

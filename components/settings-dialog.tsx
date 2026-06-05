"use client";

import { Settings } from "lucide-react";

import { useSettings } from "@/components/settings-provider";
import { Input } from "@/components/ui/input";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import { MEMOJIS } from "@/lib/memojis";
import { cn } from "@/lib/utils";

export function SettingsDialog() {
  const { name, memojiId, setName, setMemojiId } = useSettings();

  return (
    <Dialog>
      <DialogTrigger
        render={
          <button
            title="Settings"
            aria-label="Settings"
            className="flex h-9 w-9 items-center justify-center rounded-lg text-sidebar-foreground transition-colors hover:bg-sidebar-accent hover:text-sidebar-accent-foreground"
          />
        }
      >
        <Settings className="h-5 w-5" />
      </DialogTrigger>

      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Settings</DialogTitle>
          <DialogDescription>Personalize your dashboard.</DialogDescription>
        </DialogHeader>

        <div className="space-y-5">
          <div className="space-y-2">
            <label htmlFor="settings-name" className="text-sm font-medium">
              Name
            </label>
            <Input
              id="settings-name"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="Your name"
            />
            <p className="text-xs text-muted-foreground">
              Used in the greeting (&ldquo;Good morning, {name || "…"}&rdquo;).
            </p>
          </div>

          <div className="space-y-2">
            <span className="text-sm font-medium">Avatar</span>
            <div className="grid grid-cols-6 gap-2">
              {MEMOJIS.map((m) => (
                <button
                  key={m.id}
                  type="button"
                  aria-label={`Choose avatar ${m.id}`}
                  aria-pressed={m.id === memojiId}
                  onClick={() => setMemojiId(m.id)}
                  className={cn(
                    "overflow-hidden rounded-full ring-2 ring-transparent transition hover:ring-border",
                    m.id === memojiId && "ring-primary",
                  )}
                >
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img
                    src={m.url}
                    alt=""
                    className="aspect-square h-full w-full object-cover"
                  />
                </button>
              ))}
            </div>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}

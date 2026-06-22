"use client";

import { Icon } from "@iconify/react";
import settingsIcon from "@iconify-icons/ci/settings";

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
import { cn } from "@/lib/utils";

export function SettingsDialog({ triggerClassName }: { triggerClassName?: string }) {
  const { name, setName } = useSettings();

  return (
    <Dialog>
      <DialogTrigger
        render={
          <button
            title="Settings"
            aria-label="Settings"
            className={cn(
              "flex h-9 w-9 items-center justify-center rounded-lg text-muted-foreground transition-colors hover:bg-muted hover:text-foreground",
              triggerClassName,
            )}
          />
        }
      >
        <Icon icon={settingsIcon} className="size-[17px]" />
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
        </div>
      </DialogContent>
    </Dialog>
  );
}

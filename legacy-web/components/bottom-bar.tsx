"use client";

import { SettingsDialog } from "@/components/settings-dialog";
import { ThemeToggle } from "@/components/theme-toggle";

export function BottomBar() {
  return (
    <div
      className="fixed right-4 top-10 z-50 flex items-center gap-0.5 pointer-events-auto"
      style={{ WebkitAppRegion: "no-drag" } as React.CSSProperties}
    >
      <SettingsDialog triggerClassName="h-8 w-8 rounded-full text-muted-foreground/70 hover:text-foreground transition-colors duration-150" />
      <ThemeToggle className="h-8 w-8 rounded-full text-muted-foreground/70 hover:text-foreground transition-colors duration-150" />
    </div>
  );
}

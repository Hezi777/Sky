import type { ComponentType } from "react";
import {
  Calendar,
  LayoutDashboard,
  LineChart,
  ListChecks,
  Settings,
} from "lucide-react";
import { SiGithub, SiNotion, SiSpotify } from "react-icons/si";

import { Logo } from "@/components/logo";
import { cn } from "@/lib/utils";

// Decorative nav for now — the dashboard is a single page. Active = Dashboard.
// Brand icons from react-icons/si, UI icons from lucide-react (per CLAUDE.md).
const nav: { icon: ComponentType<{ className?: string }>; label: string; active?: boolean }[] = [
  { icon: LayoutDashboard, label: "Dashboard", active: true },
  { icon: Calendar, label: "Calendar" },
  { icon: ListChecks, label: "Tasks" },
  { icon: SiSpotify, label: "Spotify" },
  { icon: SiGithub, label: "GitHub" },
  { icon: SiNotion, label: "Notion" },
  { icon: LineChart, label: "Portfolio" },
];

export function Sidebar() {
  return (
    <aside className="sticky top-0 flex h-screen w-14 shrink-0 flex-col items-center gap-1 border-r border-sidebar-border bg-sidebar py-3">
      <div className="mb-2 flex h-9 w-9 items-center justify-center rounded-xl bg-sidebar-accent">
        <Logo className="h-5 w-5" />
      </div>

      <nav className="flex flex-1 flex-col items-center gap-1">
        {nav.map(({ icon: Icon, label, active }) => (
          <button
            key={label}
            title={label}
            aria-label={label}
            className={cn(
              "flex h-9 w-9 items-center justify-center rounded-lg text-sidebar-foreground transition-colors hover:bg-sidebar-accent hover:text-sidebar-accent-foreground",
              active && "bg-sidebar-accent text-sidebar-primary",
            )}
          >
            <Icon className="h-5 w-5" />
          </button>
        ))}
      </nav>

      <button
        title="Settings"
        aria-label="Settings"
        className="flex h-9 w-9 items-center justify-center rounded-lg text-sidebar-foreground transition-colors hover:bg-sidebar-accent hover:text-sidebar-accent-foreground"
      >
        <Settings className="h-5 w-5" />
      </button>
    </aside>
  );
}

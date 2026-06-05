import { ActiveProjects } from "@/components/widgets/active-projects";
import { CalendarWidget } from "@/components/widgets/calendar-widget";
import { FairWidget } from "@/components/widgets/fair-widget";
import { GithubHeatmap } from "@/components/widgets/github-heatmap";
import { GithubRepos } from "@/components/widgets/github-repos";
import { GreetingCard } from "@/components/widgets/greeting-card";
import { IBKRWidget } from "@/components/widgets/ibkr-widget";
import { NextTask } from "@/components/widgets/next-task";
import { ResourceQuickAdd } from "@/components/widgets/resource-quick-add";
import { SpotifyWidget } from "@/components/widgets/spotify-widget";
import { TickTickWidget } from "@/components/widgets/ticktick-widget";

// Content-driven bento grid (not a symmetric matrix).
// Desktop: 12-col grid; each band sums to 12 cols. Tablet (sm): 6-col;
// mobile: single column. auto-rows + row-span give tall lists real height;
// every widget Card is h-full so same-row tiles align.
export default function Home() {
  return (
    <div className="mx-auto grid max-w-7xl auto-rows-[minmax(11rem,auto)] grid-cols-1 gap-4 sm:grid-cols-6 xl:grid-cols-12">
      {/* Hero — greeting spans the full width at the top (first thing seen) */}
      <div className="sm:col-span-6 xl:col-span-12">
        <GreetingCard />
      </div>

      {/* "Now" band: schedule, tasks, and what's playing. */}
      <div className="row-span-2 sm:col-span-3 xl:col-span-4">
        <CalendarWidget />
      </div>
      <div className="row-span-2 sm:col-span-3 xl:col-span-4">
        <TickTickWidget />
      </div>
      <div className="row-span-2 sm:col-span-6 xl:col-span-4">
        <SpotifyWidget />
      </div>

      {/* FINANCE band — Portfolio (IBKR) and Fair fund side by side. */}
      <div className="row-span-2 sm:col-span-6 xl:col-span-7">
        <IBKRWidget />
      </div>
      <div className="row-span-2 sm:col-span-6 xl:col-span-5">
        <FairWidget />
      </div>

      {/* Focus + projects + repos band. */}
      <div className="row-span-2 sm:col-span-2 xl:col-span-4">
        <NextTask />
      </div>
      <div className="row-span-2 sm:col-span-2 xl:col-span-4">
        <ActiveProjects />
      </div>
      <div className="row-span-2 sm:col-span-2 xl:col-span-4">
        <GithubRepos />
      </div>

      {/* Bottom band: contribution heatmap (wide) + quick-add share one row so
          the heatmap's ~52-week strip isn't stranded in a full-width card. */}
      <div className="sm:col-span-6 xl:col-span-8">
        <GithubHeatmap />
      </div>
      <div className="sm:col-span-6 xl:col-span-4">
        <ResourceQuickAdd />
      </div>
    </div>
  );
}

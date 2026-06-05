import { ActiveProjects } from "@/components/widgets/active-projects";
import { CalendarWidget } from "@/components/widgets/calendar-widget";
import { GithubHeatmap } from "@/components/widgets/github-heatmap";
import { GithubRepos } from "@/components/widgets/github-repos";
import { GreetingCard } from "@/components/widgets/greeting-card";
import { IBKRWidget } from "@/components/widgets/ibkr-widget";
import { NextTask } from "@/components/widgets/next-task";
import { ResourceQuickAdd } from "@/components/widgets/resource-quick-add";
import { SpotifyWidget } from "@/components/widgets/spotify-widget";
import { TickTickWidget } from "@/components/widgets/ticktick-widget";

// Content-driven bento grid (not a symmetric matrix).
// Desktop: 12-col grid; tile size encodes importance + content shape.
// Tablet (sm): 6-col; Mobile: single column ordered by what Hen checks first.
// auto-rows-[minmax(11rem,auto)] + row-span-* give tall list widgets real height;
// every widget Card is h-full so same-row tiles align.
export default function Home() {
  return (
    <div className="mx-auto grid max-w-7xl auto-rows-[minmax(11rem,auto)] grid-cols-1 gap-4 sm:grid-cols-6 xl:grid-cols-12">
      {/* Hero — greeting spans the full width at the top (first thing seen) */}
      <div className="sm:col-span-6 xl:col-span-12">
        <GreetingCard />
      </div>

      {/* TODAY cluster (top-left, where the eye lands first): the schedule
          and the task list, both tall vertical lists. */}
      <div className="row-span-2 sm:col-span-3 xl:col-span-4">
        <CalendarWidget />
      </div>
      <div className="row-span-2 sm:col-span-3 xl:col-span-4">
        <TickTickWidget />
      </div>

      {/* PORTFOLIO — the heaviest object, anchors the right side as a tall
          hero metric block. */}
      <div className="row-span-3 sm:col-span-6 xl:col-span-4">
        <IBKRWidget />
      </div>

      {/* Single glanceable focus item + now-playing sit under the today
          cluster, completing the second band. */}
      <div className="sm:col-span-3 xl:col-span-4">
        <NextTask />
      </div>
      <div className="row-span-2 sm:col-span-3 xl:col-span-4">
        <SpotifyWidget />
      </div>

      {/* Projects — medium vertical list, beside Spotify. */}
      <div className="row-span-2 sm:col-span-3 xl:col-span-4">
        <ActiveProjects />
      </div>

      {/* GITHUB cluster — repos list (medium) next to the wide heatmap strip
          which needs horizontal room and little height. */}
      <div className="row-span-2 sm:col-span-3 xl:col-span-4">
        <GithubRepos />
      </div>
      <div className="sm:col-span-6 xl:col-span-8">
        <GithubHeatmap />
      </div>

      {/* Quick-add — full-width, short, at the bottom (terminal action). */}
      <div className="sm:col-span-6 xl:col-span-12">
        <ResourceQuickAdd />
      </div>
    </div>
  );
}

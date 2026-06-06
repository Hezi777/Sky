import { ActiveProjects } from "@/components/widgets/active-projects";
import { CalendarWidget } from "@/components/widgets/calendar-widget";
import { FairWidget } from "@/components/widgets/fair-widget";
import { GithubHeatmap } from "@/components/widgets/github-heatmap";
import { GreetingCard } from "@/components/widgets/greeting-card";
import { IBKRWidget } from "@/components/widgets/ibkr-widget";
import { NextTask } from "@/components/widgets/next-task";
import { ResourceQuickAdd } from "@/components/widgets/resource-quick-add";
import { SpotifyWidget } from "@/components/widgets/spotify-widget";
import { TickTickWidget } from "@/components/widgets/ticktick-widget";

function SectionLabel({ title }: { title: string }) {
  return (
    <div className="sm:col-span-6 xl:col-span-12">
      <p className="px-1 text-xs font-semibold uppercase tracking-[0.18em] text-muted-foreground">
        {title}
      </p>
    </div>
  );
}

// Content-driven dashboard grid. Each band reflects a real morning question:
// what is next, how money is doing, what to focus on, and recent activity.
export default function Home() {
  return (
    <div className="mx-auto grid max-w-7xl grid-cols-1 gap-4 sm:grid-cols-6 xl:grid-cols-12">
      <div className="sm:col-span-6 xl:col-span-12">
        <GreetingCard />
      </div>

      <SectionLabel title="Today" />
      <div className="grid gap-4 sm:col-span-6 xl:col-span-12 xl:grid-cols-[minmax(0,1.08fr)_minmax(22rem,0.92fr)]">
        <CalendarWidget />
        <div className="grid min-h-full gap-4 xl:grid-rows-[1fr_auto]">
          <TickTickWidget />
          <SpotifyWidget />
        </div>
      </div>

      <SectionLabel title="Money" />
      <div className="sm:col-span-6 xl:col-span-8">
        <IBKRWidget />
      </div>
      <div className="sm:col-span-6 xl:col-span-4">
        <FairWidget />
      </div>

      <SectionLabel title="Focus" />
      <div className="sm:col-span-3 xl:col-span-5">
        <ActiveProjects />
      </div>
      <div className="sm:col-span-3 xl:col-span-4">
        <NextTask />
      </div>
      <div className="sm:col-span-6 xl:col-span-3">
        <ResourceQuickAdd />
      </div>

      <SectionLabel title="Activity" />
      <div className="sm:col-span-6 xl:col-span-12">
        <GithubHeatmap />
      </div>
    </div>
  );
}

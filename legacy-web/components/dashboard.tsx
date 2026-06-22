"use client";

import { HeroZone } from "@/components/hero-zone";
import { SkyAmbient } from "@/components/sky-ambient";
import { ActiveProjects } from "@/components/widgets/active-projects";
import { CalendarWidget } from "@/components/widgets/calendar-widget";
import { FairWidget } from "@/components/widgets/fair-widget";
import { GithubHeatmap } from "@/components/widgets/github-heatmap";
import { IBKRWidget } from "@/components/widgets/ibkr-widget";
import { NextTask } from "@/components/widgets/next-task";
import { ResourceQuickAdd } from "@/components/widgets/resource-quick-add";
import { SpotifyWidget } from "@/components/widgets/spotify-widget";
import { TickTickWidget } from "@/components/widgets/ticktick-widget";
import { useCloudState } from "@/hooks/use-cloud-state";

export function Dashboard() {
  const { state: cloudState } = useCloudState();

  return (
    <>
      <SkyAmbient state={cloudState} />

      <div className="relative z-10">
        <HeroZone cloudState={cloudState} />

        <div className="grid grid-cols-1 gap-3 sm:grid-cols-6 xl:grid-cols-12">
          <div className="grid gap-3 sm:col-span-6 xl:col-span-12 xl:grid-cols-[minmax(0,1.08fr)_minmax(22rem,0.92fr)]">
            <CalendarWidget />
            <div className="grid min-h-full gap-3 xl:grid-rows-[1fr_auto]">
              <TickTickWidget />
              <SpotifyWidget />
            </div>
          </div>

          <div className="sm:col-span-6 xl:col-span-8">
            <IBKRWidget />
          </div>
          <div className="sm:col-span-6 xl:col-span-4">
            <FairWidget />
          </div>

          <div className="sm:col-span-3 xl:col-span-5">
            <ActiveProjects />
          </div>
          <div className="sm:col-span-3 xl:col-span-4">
            <NextTask />
          </div>
          <div className="sm:col-span-6 xl:col-span-3">
            <ResourceQuickAdd />
          </div>

          <div className="sm:col-span-6 xl:col-span-12">
            <GithubHeatmap />
          </div>
        </div>
      </div>
    </>
  );
}

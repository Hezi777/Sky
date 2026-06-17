"use client";

import type { ComponentType } from "react";

import { ActiveProjects } from "@/components/widgets/active-projects";
import { CalendarWidget } from "@/components/widgets/calendar-widget";
import { FairWidget } from "@/components/widgets/fair-widget";
import { GithubHeatmap } from "@/components/widgets/github-heatmap";
import { IBKRWidget } from "@/components/widgets/ibkr-widget";
import { NextTask } from "@/components/widgets/next-task";
import { ResourceQuickAdd } from "@/components/widgets/resource-quick-add";
import { SpotifyWidget } from "@/components/widgets/spotify-widget";
import { TickTickWidget } from "@/components/widgets/ticktick-widget";
import type { WidgetSize } from "@/lib/widgets/registry";

export type WidgetComponent = ComponentType<{ size: WidgetSize }>;

// Existing widgets don't take a `size` prop yet (Phase B adds size-aware
// rendering); for now every size renders the same default content.
export const WIDGET_COMPONENTS: Record<string, WidgetComponent> = {
  "calendar-today": () => <CalendarWidget />,
  "ticktick-tasks": () => <TickTickWidget />,
  "spotify-now-playing": () => <SpotifyWidget />,
  "ibkr-portfolio": () => <IBKRWidget />,
  "fair-tracker": () => <FairWidget />,
  "notion-active-projects": () => <ActiveProjects />,
  "notion-next-task": () => <NextTask />,
  "notion-quick-add": () => <ResourceQuickAdd />,
  "github-heatmap": () => <GithubHeatmap />,
};

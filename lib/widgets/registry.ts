import type { ComponentType, SVGProps } from "react";
import {
  BookOpen,
  Calendar as CalendarIcon,
  CloudSun,
  Flame,
  ListTodo,
  TrendingUp,
  Trophy,
  Wallet,
} from "lucide-react";
import { SiGithub, SiNotion, SiSpotify } from "react-icons/si";

export type WidgetSize = "small" | "medium" | "large";

export type WidgetIcon = ComponentType<SVGProps<SVGSVGElement>>;

export interface AppDef {
  id: string;
  name: string;
  icon: WidgetIcon;
}

export interface WidgetSizeSpec {
  w: number;
  h: number;
}

export interface WidgetDef {
  id: string;
  appId: string;
  name: string;
  description: string;
  icon: WidgetIcon;
  availableSizes: WidgetSize[];
  defaultSize: WidgetSize;
  sizeSpecs: Record<WidgetSize, WidgetSizeSpec>;
  defaultVisible: boolean;
  /** Locked widgets (greeting) are always shown, full width, and not in the gallery. */
  locked?: boolean;
}

export const APPS: AppDef[] = [
  { id: "notion", name: "Notion", icon: SiNotion },
  { id: "spotify", name: "Spotify", icon: SiSpotify },
  { id: "ibkr", name: "IBKR", icon: TrendingUp },
  { id: "github", name: "GitHub", icon: SiGithub },
  { id: "calendar", name: "Google Calendar", icon: CalendarIcon },
  { id: "ticktick", name: "TickTick", icon: ListTodo },
  { id: "fair", name: "Fair", icon: Wallet },
  { id: "weather", name: "Weather", icon: CloudSun },
  { id: "shabbat", name: "Shabbat Times", icon: Flame },
  { id: "worldcup", name: "World Cup", icon: Trophy },
];

export const WIDGET_DEFS: WidgetDef[] = [
  {
    id: "greeting",
    appId: "core",
    name: "Greeting",
    description: "Personalized morning greeting and day progress.",
    icon: CalendarIcon,
    availableSizes: ["large"],
    defaultSize: "large",
    sizeSpecs: { small: { w: 12, h: 2 }, medium: { w: 12, h: 2 }, large: { w: 12, h: 2 } },
    defaultVisible: true,
    locked: true,
  },
  {
    id: "calendar-today",
    appId: "calendar",
    name: "Today's Schedule",
    description: "Today's calendar events at a glance.",
    icon: CalendarIcon,
    availableSizes: ["small", "medium", "large"],
    defaultSize: "medium",
    sizeSpecs: {
      small: { w: 3, h: 3 },
      medium: { w: 7, h: 5 },
      large: { w: 8, h: 6 },
    },
    defaultVisible: true,
  },
  {
    id: "ticktick-tasks",
    appId: "ticktick",
    name: "Tasks",
    description: "Your TickTick task list with priorities and tags.",
    icon: ListTodo,
    availableSizes: ["small", "medium", "large"],
    defaultSize: "medium",
    sizeSpecs: {
      small: { w: 3, h: 2 },
      medium: { w: 5, h: 3 },
      large: { w: 5, h: 5 },
    },
    defaultVisible: true,
  },
  {
    id: "spotify-now-playing",
    appId: "spotify",
    name: "Now Playing",
    description: "See what's currently playing and recently played tracks.",
    icon: SiSpotify,
    availableSizes: ["small", "medium", "large"],
    defaultSize: "medium",
    sizeSpecs: {
      small: { w: 3, h: 2 },
      medium: { w: 5, h: 2 },
      large: { w: 5, h: 4 },
    },
    defaultVisible: true,
  },
  {
    id: "ibkr-portfolio",
    appId: "ibkr",
    name: "Portfolio",
    description: "Net worth, allocation, and positions from IBKR.",
    icon: TrendingUp,
    availableSizes: ["small", "medium", "large"],
    defaultSize: "large",
    sizeSpecs: {
      small: { w: 3, h: 2 },
      medium: { w: 6, h: 4 },
      large: { w: 8, h: 5 },
    },
    defaultVisible: true,
  },
  {
    id: "fair-tracker",
    appId: "fair",
    name: "Net Worth Tracker",
    description: "Personal net worth and DCA contribution tracking.",
    icon: Wallet,
    availableSizes: ["small", "medium", "large"],
    defaultSize: "medium",
    sizeSpecs: {
      small: { w: 3, h: 2 },
      medium: { w: 4, h: 5 },
      large: { w: 5, h: 6 },
    },
    defaultVisible: true,
  },
  {
    id: "notion-active-projects",
    appId: "notion",
    name: "Active Projects",
    description: "Projects currently in progress or finishing up.",
    icon: SiNotion,
    availableSizes: ["small", "medium", "large"],
    defaultSize: "medium",
    sizeSpecs: {
      small: { w: 3, h: 2 },
      medium: { w: 5, h: 3 },
      large: { w: 6, h: 4 },
    },
    defaultVisible: true,
  },
  {
    id: "notion-next-task",
    appId: "notion",
    name: "Next Task",
    description: "Your single highest-priority next action.",
    icon: SiNotion,
    availableSizes: ["small", "medium", "large"],
    defaultSize: "medium",
    sizeSpecs: {
      small: { w: 3, h: 2 },
      medium: { w: 4, h: 3 },
      large: { w: 5, h: 4 },
    },
    defaultVisible: true,
  },
  {
    id: "notion-quick-add",
    appId: "notion",
    name: "Quick Add Resource",
    description: "Save and auto-tag a link to your Notion resources.",
    icon: SiNotion,
    availableSizes: ["small", "medium", "large"],
    defaultSize: "medium",
    sizeSpecs: {
      small: { w: 3, h: 2 },
      medium: { w: 3, h: 3 },
      large: { w: 4, h: 4 },
    },
    defaultVisible: true,
  },
  {
    id: "notion-book-tracker",
    appId: "notion",
    name: "Current Book",
    description: "What you're currently reading, with progress.",
    icon: BookOpen,
    availableSizes: ["small", "medium", "large"],
    defaultSize: "medium",
    sizeSpecs: {
      small: { w: 3, h: 2 },
      medium: { w: 4, h: 3 },
      large: { w: 5, h: 4 },
    },
    // Flipped to true once the widget component ships (Phase C).
    defaultVisible: false,
  },
  {
    id: "github-heatmap",
    appId: "github",
    name: "Activity Heatmap",
    description: "GitHub contribution heatmap and recent repos.",
    icon: SiGithub,
    availableSizes: ["small", "medium", "large"],
    defaultSize: "large",
    sizeSpecs: {
      small: { w: 4, h: 2 },
      medium: { w: 8, h: 3 },
      large: { w: 12, h: 4 },
    },
    defaultVisible: true,
  },
  {
    id: "weather-current",
    appId: "weather",
    name: "Weather",
    description: "Current conditions and forecast for your location.",
    icon: CloudSun,
    availableSizes: ["small", "medium", "large"],
    defaultSize: "small",
    sizeSpecs: {
      small: { w: 3, h: 2 },
      medium: { w: 4, h: 3 },
      large: { w: 6, h: 4 },
    },
    // Flipped to true once the widget component ships (Phase C).
    defaultVisible: false,
  },
  {
    id: "shabbat-times",
    appId: "shabbat",
    name: "Shabbat Times",
    description: "Candle lighting and havdalah times for your location.",
    icon: Flame,
    availableSizes: ["small", "medium", "large"],
    defaultSize: "medium",
    sizeSpecs: {
      small: { w: 3, h: 2 },
      medium: { w: 4, h: 3 },
      large: { w: 5, h: 4 },
    },
    defaultVisible: false,
  },
  {
    id: "worldcup-scores",
    appId: "worldcup",
    name: "World Cup Scores",
    description: "Live scores and fixtures for the World Cup.",
    icon: Trophy,
    availableSizes: ["small", "medium", "large"],
    defaultSize: "medium",
    sizeSpecs: {
      small: { w: 3, h: 2 },
      medium: { w: 5, h: 3 },
      large: { w: 6, h: 5 },
    },
    defaultVisible: false,
  },
];

export function getWidgetDef(widgetDefId: string): WidgetDef | undefined {
  return WIDGET_DEFS.find((w) => w.id === widgetDefId);
}

export function getAppDef(appId: string): AppDef | undefined {
  return APPS.find((a) => a.id === appId);
}

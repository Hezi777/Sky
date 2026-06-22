// Typed interfaces for every API route response. See docs/PLAN.md (Widget Specs).
// Each /api/* route returns one of these shapes (or { error } on failure).

export interface ApiError {
  error: string;
}

// --- Backend status ---------------------------------------------------------

export interface HealthResponse {
  status: "ok";
  ready: true;
  version: string;
}

export interface IntegrationConfigStatus {
  configured: boolean;
  missing: string[];
}

export interface IntegrationsStatusResponse {
  integrations: {
    googleCalendar: IntegrationConfigStatus;
    tickTick: IntegrationConfigStatus;
    spotify: IntegrationConfigStatus;
    strava: IntegrationConfigStatus;
    stocks: IntegrationConfigStatus;
    github: IntegrationConfigStatus;
    notionReading: IntegrationConfigStatus;
    ibkr: IntegrationConfigStatus;
    groq: IntegrationConfigStatus;
  };
}

// --- Spotify ---------------------------------------------------------------

export interface SpotifyTrack {
  title: string;
  artist: string;
  albumArt: string | null;
  url: string;
}

export interface SpotifyNowPlaying extends SpotifyTrack {
  isPlaying: boolean;
  progressMs: number;
  durationMs: number;
}

export interface SpotifyResponse {
  nowPlaying: SpotifyNowPlaying | null;
  recent: SpotifyTrack[];
}

// --- GitHub ----------------------------------------------------------------

export interface GithubRepo {
  name: string;
  description: string | null;
  language: string | null;
  stars: number;
  pushedAt: string; // ISO
  url: string;
}

export interface GithubContributionDay {
  date: string; // YYYY-MM-DD
  count: number;
  level: 0 | 1 | 2 | 3 | 4;
}

export interface GithubResponse {
  repos: GithubRepo[];
  contributions: GithubContributionDay[];
  totalContributions: number;
}

// --- Notion ----------------------------------------------------------------

export interface NotionProject {
  id: string;
  name: string;
  stage: string;
  type: string | null;
  stack: string | null;
  nextAction: string | null;
  url: string;
}

export type NotionNextTask = NotionProject;

// --- Google Calendar -------------------------------------------------------

export interface CalendarEvent {
  id: string;
  title: string;
  start: string; // ISO
  end: string; // ISO
  allDay: boolean;
  location: string | null;
  colorId: string | null;
  url: string | null;
}

// --- TickTick --------------------------------------------------------------

export type TickTickPriority = "none" | "low" | "medium" | "high";

export interface TickTickTask {
  id: string;
  projectId: string;
  title: string;
  priority: TickTickPriority;
  dueDate: string | null; // ISO, null if all-day/no time
  tags: string[];
  subtaskCount: number;
}

// --- IBKR ------------------------------------------------------------------

export interface IbkrPosition {
  ticker: string;
  shares: number;
  avgCost: number;
  currentPrice: number;
  marketValue: number;
  pnlPercent: number;
}

export interface IbkrSummary {
  totalValue: number;
  dayPnl: number | null;
  unrealizedPnl: number;
  unrealizedPnlPercent: number;
}

export interface IbkrResponse {
  source: "gateway" | "flex";
  asOf: string | null;
  summary: IbkrSummary;
  positions: IbkrPosition[];
}

// --- AI (Groq) -------------------------------------------------------------

export interface GreetingResponse {
  message: string;
}

export type DashboardSignalPeriod = "morning" | "afternoon" | "evening" | "night";
export type DashboardSignalLoad = "unknown" | "clear" | "light" | "busy";
export type DashboardSignalMomentum = "unknown" | "quiet" | "active" | "strong";
export type DashboardSignalTrend = "unknown" | "down" | "flat" | "up";
export type DashboardSignalRecency = "unknown" | "recent" | "stale";

export interface DashboardAISignals {
  period: DashboardSignalPeriod;
  calendarLoad: DashboardSignalLoad;
  taskLoad: DashboardSignalLoad;
  codingMomentum: DashboardSignalMomentum;
  portfolioTrend: DashboardSignalTrend;
  musicPlaying?: boolean;
  exerciseRecency: DashboardSignalRecency;
  readingActive?: boolean;
}

export interface ResourceProperties {
  Name: string;
  Description: string;
  Category: string;
  Status: string;
}

// --- Fair (Israeli mutual fund DCA tracker) --------------------------------

export interface FairPrice {
  price: number; // quoted unit price (Maya scale, used as-is)
  asOf: string; // ISO date the price is valid for
  currency: string; // "ILS"
  source: string; // e.g. "Maya / TASE"
  fundName?: string;
}

export interface FairContribution {
  id: string;
  date: string; // YYYY-MM-DD
  amount: number; // ₪ invested
  units: number; // units bought
}

export interface FairConfig {
  fundNumber: string;
  fundName: string;
  manualPrice?: number; // ₪ per unit; overrides the live price when set
  contributions: FairContribution[];
}

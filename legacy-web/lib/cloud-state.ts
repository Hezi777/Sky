export type CloudInput = {
  hour: number;
  githubCommits: number;
  ticktickCompleted: number;
  sleepScore?: number;
  daysSinceActivity?: number;
  portfolioChangePercent?: number;
};

export type CloudState =
  | "hero"
  | "sleeping"
  | "stretching"
  | "happy"
  | "confident"
  | "droopy"
  | "calm";

export const CLOUD_ASSET_MAP: Record<CloudState, string> = {
  hero: "/assets/cloud/cloud-hero.png",
  sleeping: "/assets/cloud/cloud-sleeping.png",
  stretching: "/assets/cloud/cloud-stretching.png",
  happy: "/assets/cloud/cloud-happy.png",
  confident: "/assets/cloud/cloud-confident.png",
  droopy: "/assets/cloud/cloud-droopy.png",
  calm: "/assets/cloud/cloud-calm.png",
};

/** Determine cloud mood from dashboard data. First matching rule wins. */
export function getCloudState(input: CloudInput): CloudState {
  const { hour, githubCommits, ticktickCompleted, sleepScore, daysSinceActivity, portfolioChangePercent } = input;

  if (hour >= 22 || hour < 6) return "sleeping";
  if (hour >= 6 && hour < 9) return "stretching";
  if (githubCommits > 3 || ticktickCompleted > 5) return "happy";
  if (portfolioChangePercent !== undefined && portfolioChangePercent > 1) return "confident";
  if (
    (sleepScore !== undefined && sleepScore < 60) ||
    (daysSinceActivity !== undefined && daysSinceActivity >= 2)
  ) return "droopy";
  if (hour >= 18 && hour < 22) return "calm";
  return "hero";
}

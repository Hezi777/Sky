import type { GithubContributionDay, GithubRepo, GithubResponse } from "@/lib/types";

const BASE = "https://api.github.com";

function authHeaders() {
  return {
    Authorization: `Bearer ${process.env.GITHUB_PAT}`,
    "User-Agent": "sky",
    Accept: "application/vnd.github+json",
  };
}

function toLevel(count: number): 0 | 1 | 2 | 3 | 4 {
  if (count === 0) return 0;
  if (count <= 3) return 1;
  if (count <= 6) return 2;
  if (count <= 9) return 3;
  return 4;
}

export async function getRecentRepos(): Promise<GithubRepo[]> {
  const res = await fetch(
    `${BASE}/user/repos?sort=pushed&per_page=4`,
    { headers: authHeaders() }
  );
  if (!res.ok) throw new Error(`GitHub repos ${res.status}`);
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const data: any[] = await res.json();
  return data.map((r) => ({
    name: r.name as string,
    description: (r.description as string | null) ?? null,
    language: (r.language as string | null) ?? null,
    stars: r.stargazers_count as number,
    pushedAt: r.pushed_at as string,
    url: r.html_url as string,
  }));
}

const CONTRIBUTIONS_QUERY = `
  query {
    viewer {
      contributionsCollection {
        contributionCalendar {
          totalContributions
          weeks {
            contributionDays {
              date
              contributionCount
            }
          }
        }
      }
    }
  }
`;

export async function getContributions(): Promise<{
  contributions: GithubContributionDay[];
  totalContributions: number;
}> {
  const res = await fetch(`${BASE}/graphql`, {
    method: "POST",
    headers: { ...authHeaders(), "Content-Type": "application/json" },
    body: JSON.stringify({ query: CONTRIBUTIONS_QUERY }),
  });
  if (!res.ok) throw new Error(`GitHub GraphQL ${res.status}`);
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const json: any = await res.json();
  const calendar =
    json.data.viewer.contributionsCollection.contributionCalendar;
  const totalContributions: number = calendar.totalContributions;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const contributions: GithubContributionDay[] = calendar.weeks.flatMap((w: any) =>
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    w.contributionDays.map((d: any) => ({
      date: d.date as string,
      count: d.contributionCount as number,
      level: toLevel(d.contributionCount as number),
    }))
  );
  return { contributions, totalContributions };
}

export async function getGithubData(): Promise<GithubResponse> {
  const [repos, { contributions, totalContributions }] = await Promise.all([
    getRecentRepos(),
    getContributions(),
  ]);
  return { repos, contributions, totalContributions };
}

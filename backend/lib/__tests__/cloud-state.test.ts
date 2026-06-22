import { describe, expect, it } from "vitest";
import { getCloudState, type CloudInput } from "../cloud-state";

const base: CloudInput = { hour: 12, githubCommits: 0, ticktickCompleted: 0 };

describe("getCloudState", () => {
  it("returns sleeping at night (>= 22)", () => {
    expect(getCloudState({ ...base, hour: 23 })).toBe("sleeping");
  });

  it("returns sleeping before dawn (< 6)", () => {
    expect(getCloudState({ ...base, hour: 3 })).toBe("sleeping");
  });

  it("returns stretching in the early morning (6–9)", () => {
    expect(getCloudState({ ...base, hour: 7 })).toBe("stretching");
  });

  it("returns happy when github commits > 3", () => {
    expect(getCloudState({ ...base, hour: 14, githubCommits: 5 })).toBe("happy");
  });

  it("returns happy when ticktick completed > 5", () => {
    expect(getCloudState({ ...base, hour: 14, ticktickCompleted: 8 })).toBe("happy");
  });

  it("returns confident when portfolio up > 1%", () => {
    expect(getCloudState({ ...base, hour: 14, portfolioChangePercent: 2.5 })).toBe("confident");
  });

  it("returns droopy when sleep score < 60", () => {
    expect(getCloudState({ ...base, hour: 14, sleepScore: 40 })).toBe("droopy");
  });

  it("returns droopy when no activity for >= 2 days", () => {
    expect(getCloudState({ ...base, hour: 14, daysSinceActivity: 3 })).toBe("droopy");
  });

  it("returns calm in the evening (18–22)", () => {
    expect(getCloudState({ ...base, hour: 19 })).toBe("calm");
  });

  it("returns hero as fallback", () => {
    expect(getCloudState({ ...base, hour: 14 })).toBe("hero");
  });

  it("sleeping takes priority over happy (late-night coding)", () => {
    expect(getCloudState({ ...base, hour: 23, githubCommits: 10 })).toBe("sleeping");
  });

  it("stretching takes priority over happy (early-morning tasks)", () => {
    expect(getCloudState({ ...base, hour: 7, ticktickCompleted: 10 })).toBe("stretching");
  });
});

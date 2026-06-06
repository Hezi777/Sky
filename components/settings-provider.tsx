"use client";

import { createContext, useContext, useEffect, useState } from "react";

import { DEFAULT_MEMOJI_ID, MEMOJIS } from "@/lib/memojis";

const STORAGE_KEY = "sky:settings";
const LEGACY_MEMOJI_KEY = "sky:memoji";
const DEFAULT_NAME = "Hen";

type Settings = { name: string; memojiId: string; profileImageUrl: string | null };

type SettingsContextValue = Settings & {
  ready: boolean; // false until hydrated from localStorage (SSR-safe)
  setName: (name: string) => void;
  setMemojiId: (id: string) => void;
  setProfileImageUrl: (url: string | null) => void;
};

const SettingsContext = createContext<SettingsContextValue | null>(null);

export function SettingsProvider({ children }: { children: React.ReactNode }) {
  const [name, setName] = useState(DEFAULT_NAME);
  const [memojiId, setMemojiId] = useState(DEFAULT_MEMOJI_ID);
  const [profileImageUrl, setProfileImageUrl] = useState<string | null>(null);
  const [ready, setReady] = useState(false);

  // Hydrate from localStorage once on mount. Defaults render on the server and
  // the first client render (ready=false), so there is no hydration mismatch.
  useEffect(() => {
    const next: Settings = {
      name: DEFAULT_NAME,
      memojiId: DEFAULT_MEMOJI_ID,
      profileImageUrl: null,
    };
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (raw) {
        const s = JSON.parse(raw) as Partial<Settings>;
        if (typeof s.name === "string" && s.name.trim()) next.name = s.name;
        if (typeof s.memojiId === "string" && MEMOJIS.some((m) => m.id === s.memojiId)) {
          next.memojiId = s.memojiId;
        }
        if (typeof s.profileImageUrl === "string" && s.profileImageUrl.startsWith("data:image/")) {
          next.profileImageUrl = s.profileImageUrl;
        }
      } else {
        // Migrate the old standalone memoji key, if present.
        const legacy = localStorage.getItem(LEGACY_MEMOJI_KEY);
        if (legacy && MEMOJIS.some((m) => m.id === legacy)) next.memojiId = legacy;
      }
    } catch {
      /* ignore parse / access errors */
    }
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setName(next.name);
    setMemojiId(next.memojiId);
    setProfileImageUrl(next.profileImageUrl);
    setReady(true);
  }, []);

  // Persist on change (after hydration so we don't clobber stored values).
  useEffect(() => {
    if (!ready) return;
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify({ name, memojiId, profileImageUrl }));
    } catch {
      /* ignore quota / private-mode errors */
    }
  }, [name, memojiId, profileImageUrl, ready]);

  function chooseMemoji(id: string) {
    setMemojiId(id);
    setProfileImageUrl(null);
  }

  return (
    <SettingsContext.Provider
      value={{
        name,
        memojiId,
        profileImageUrl,
        ready,
        setName,
        setMemojiId: chooseMemoji,
        setProfileImageUrl,
      }}
    >
      {children}
    </SettingsContext.Provider>
  );
}

export function useSettings() {
  const ctx = useContext(SettingsContext);
  if (!ctx) throw new Error("useSettings must be used within SettingsProvider");
  return ctx;
}

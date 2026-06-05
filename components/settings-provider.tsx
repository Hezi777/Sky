"use client";

import { createContext, useContext, useEffect, useState } from "react";

import { DEFAULT_MEMOJI_ID, MEMOJIS } from "@/lib/memojis";

const STORAGE_KEY = "sky:settings";
const LEGACY_MEMOJI_KEY = "sky:memoji";
const DEFAULT_NAME = "Hen";

type Settings = { name: string; memojiId: string };

type SettingsContextValue = Settings & {
  ready: boolean; // false until hydrated from localStorage (SSR-safe)
  setName: (name: string) => void;
  setMemojiId: (id: string) => void;
};

const SettingsContext = createContext<SettingsContextValue | null>(null);

export function SettingsProvider({ children }: { children: React.ReactNode }) {
  const [name, setName] = useState(DEFAULT_NAME);
  const [memojiId, setMemojiId] = useState(DEFAULT_MEMOJI_ID);
  const [ready, setReady] = useState(false);

  // Hydrate from localStorage once on mount. Defaults render on the server and
  // the first client render (ready=false), so there is no hydration mismatch.
  useEffect(() => {
    const next: Settings = { name: DEFAULT_NAME, memojiId: DEFAULT_MEMOJI_ID };
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (raw) {
        const s = JSON.parse(raw) as Partial<Settings>;
        if (typeof s.name === "string" && s.name.trim()) next.name = s.name;
        if (typeof s.memojiId === "string" && MEMOJIS.some((m) => m.id === s.memojiId)) {
          next.memojiId = s.memojiId;
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
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setMemojiId(next.memojiId);
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setReady(true);
  }, []);

  // Persist on change (after hydration so we don't clobber stored values).
  useEffect(() => {
    if (!ready) return;
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify({ name, memojiId }));
    } catch {
      /* ignore quota / private-mode errors */
    }
  }, [name, memojiId, ready]);

  return (
    <SettingsContext.Provider value={{ name, memojiId, ready, setName, setMemojiId }}>
      {children}
    </SettingsContext.Provider>
  );
}

export function useSettings() {
  const ctx = useContext(SettingsContext);
  if (!ctx) throw new Error("useSettings must be used within SettingsProvider");
  return ctx;
}

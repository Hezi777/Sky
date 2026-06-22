"use client";

import { createContext, useContext, useEffect, useState } from "react";

const STORAGE_KEY = "sky:settings";
const DEFAULT_NAME = "Hen";

type Settings = { name: string };

type SettingsContextValue = Settings & {
  ready: boolean;
  setName: (name: string) => void;
};

const SettingsContext = createContext<SettingsContextValue | null>(null);

function readStoredName() {
  let stored = DEFAULT_NAME;
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (raw) {
      const s = JSON.parse(raw) as Partial<Settings>;
      if (typeof s.name === "string" && s.name.trim()) stored = s.name;
    }
  } catch {
    /* ignore */
  }
  return stored;
}

export function SettingsProvider({ children }: { children: React.ReactNode }) {
  const [name, setName] = useState(DEFAULT_NAME);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    const timeout = window.setTimeout(() => {
      setName(readStoredName());
      setReady(true);
    }, 0);
    return () => window.clearTimeout(timeout);
  }, []);

  useEffect(() => {
    if (!ready) return;
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify({ name }));
    } catch {
      /* ignore */
    }
  }, [name, ready]);

  return (
    <SettingsContext.Provider value={{ name, ready, setName }}>
      {children}
    </SettingsContext.Provider>
  );
}

export function useSettings() {
  const ctx = useContext(SettingsContext);
  if (!ctx) throw new Error("useSettings must be used within SettingsProvider");
  return ctx;
}

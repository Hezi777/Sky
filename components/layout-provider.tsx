"use client";

import { createContext, useContext, useEffect, useState } from "react";

import {
  getWidgetDef,
  WIDGET_DEFS,
  type WidgetSize,
} from "@/lib/widgets/registry";

const STORAGE_KEY = "sky:layout";
const SCHEMA_VERSION = 1;

export interface WidgetInstance {
  id: string; // == widgetDefId (one instance per widget definition, for now)
  widgetDefId: string;
  size: WidgetSize;
  x: number;
  y: number;
  w: number;
  h: number;
}

export interface RglLayoutItem {
  i: string;
  x: number;
  y: number;
  w: number;
  h: number;
}

interface StoredLayout {
  version: number;
  widgets: WidgetInstance[];
}

type LayoutContextValue = {
  widgets: WidgetInstance[];
  ready: boolean;
  addWidget: (widgetDefId: string, size?: WidgetSize) => void;
  removeWidget: (instanceId: string) => void;
  setWidgetSize: (instanceId: string, size: WidgetSize) => void;
  updateLayout: (layout: RglLayoutItem[]) => void;
  resetToDefault: () => void;
};

const LayoutContext = createContext<LayoutContextValue | null>(null);

// Mirrors the pre-upgrade static grid in app/page.tsx (12-col layout).
function buildDefaultLayout(): WidgetInstance[] {
  const positions: Record<string, { x: number; y: number }> = {
    "calendar-today": { x: 0, y: 0 },
    "ticktick-tasks": { x: 7, y: 0 },
    "spotify-now-playing": { x: 7, y: 3 },
    "ibkr-portfolio": { x: 0, y: 5 },
    "fair-tracker": { x: 8, y: 5 },
    "notion-active-projects": { x: 0, y: 10 },
    "notion-next-task": { x: 5, y: 10 },
    "notion-quick-add": { x: 9, y: 10 },
    "github-heatmap": { x: 0, y: 13 },
  };

  return WIDGET_DEFS.filter((def) => def.defaultVisible && !def.locked)
    .map((def) => {
      const pos = positions[def.id];
      const spec = def.sizeSpecs[def.defaultSize];
      if (!pos || !spec) return null;
      return {
        id: def.id,
        widgetDefId: def.id,
        size: def.defaultSize,
        x: pos.x,
        y: pos.y,
        w: spec.w,
        h: spec.h,
      };
    })
    .filter((w): w is WidgetInstance => w !== null);
}

function nextSlot(widgets: WidgetInstance[], w: number) {
  const maxY = widgets.reduce((max, item) => Math.max(max, item.y + item.h), 0);
  return { x: 0, y: maxY, w };
}

export function LayoutProvider({ children }: { children: React.ReactNode }) {
  const [widgets, setWidgets] = useState<WidgetInstance[]>(buildDefaultLayout);
  const [ready, setReady] = useState(false);

  // Hydrate from localStorage once on mount (SSR-safe, like settings-provider).
  useEffect(() => {
    let next = buildDefaultLayout();
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (raw) {
        const stored = JSON.parse(raw) as Partial<StoredLayout>;
        if (stored.version === SCHEMA_VERSION && Array.isArray(stored.widgets)) {
          const known = stored.widgets.filter((w) => getWidgetDef(w.widgetDefId));

          // Merge in any widget defs that became default-visible since this
          // layout was saved (e.g. newly shipped widgets).
          const existingIds = new Set(known.map((w) => w.widgetDefId));
          const additions = WIDGET_DEFS.filter(
            (def) => def.defaultVisible && !def.locked && !existingIds.has(def.id),
          ).map((def) => {
            const spec = def.sizeSpecs[def.defaultSize];
            const slot = nextSlot(known, spec.w);
            return {
              id: def.id,
              widgetDefId: def.id,
              size: def.defaultSize,
              x: slot.x,
              y: slot.y,
              w: slot.w,
              h: spec.h,
            };
          });

          next = [...known, ...additions];
        }
      }
    } catch {
      /* ignore parse / access errors */
    }
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setWidgets(next);
    setReady(true);
  }, []);

  // Persist on change (after hydration so we don't clobber stored values).
  useEffect(() => {
    if (!ready) return;
    try {
      const payload: StoredLayout = { version: SCHEMA_VERSION, widgets };
      localStorage.setItem(STORAGE_KEY, JSON.stringify(payload));
    } catch {
      /* ignore quota / private-mode errors */
    }
  }, [widgets, ready]);

  function addWidget(widgetDefId: string, size?: WidgetSize) {
    const def = getWidgetDef(widgetDefId);
    if (!def || def.locked) return;

    setWidgets((prev) => {
      if (prev.some((w) => w.widgetDefId === widgetDefId)) return prev;
      const targetSize = size ?? def.defaultSize;
      const spec = def.sizeSpecs[targetSize] ?? def.sizeSpecs[def.defaultSize];
      const slot = nextSlot(prev, spec.w);
      return [
        ...prev,
        {
          id: widgetDefId,
          widgetDefId,
          size: targetSize,
          x: slot.x,
          y: slot.y,
          w: slot.w,
          h: spec.h,
        },
      ];
    });
  }

  function removeWidget(instanceId: string) {
    setWidgets((prev) => prev.filter((w) => w.id !== instanceId));
  }

  function setWidgetSize(instanceId: string, size: WidgetSize) {
    setWidgets((prev) =>
      prev.map((w) => {
        if (w.id !== instanceId) return w;
        const def = getWidgetDef(w.widgetDefId);
        const spec = def?.sizeSpecs[size];
        if (!spec) return w;
        return { ...w, size, w: spec.w, h: spec.h };
      }),
    );
  }

  function updateLayout(layout: RglLayoutItem[]) {
    setWidgets((prev) =>
      prev.map((w) => {
        const item = layout.find((l) => l.i === w.id);
        if (!item) return w;
        return { ...w, x: item.x, y: item.y, w: item.w, h: item.h };
      }),
    );
  }

  function resetToDefault() {
    setWidgets(buildDefaultLayout());
  }

  return (
    <LayoutContext.Provider
      value={{ widgets, ready, addWidget, removeWidget, setWidgetSize, updateLayout, resetToDefault }}
    >
      {children}
    </LayoutContext.Provider>
  );
}

export function useLayout() {
  const ctx = useContext(LayoutContext);
  if (!ctx) throw new Error("useLayout must be used within LayoutProvider");
  return ctx;
}

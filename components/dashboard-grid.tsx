"use client";

import { ResponsiveGridLayout, useContainerWidth } from "react-grid-layout";

import { useLayout } from "@/components/layout-provider";
import { WIDGET_COMPONENTS } from "@/lib/widgets/component-map";

const BREAKPOINTS = { lg: 1024, sm: 640, xs: 0 };
const COLS = { lg: 12, sm: 6, xs: 1 };

export function DashboardGrid() {
  const { widgets, ready, updateLayout } = useLayout();
  const { width, containerRef, mounted } = useContainerWidth({ measureBeforeMount: true });

  const renderable = widgets.filter((w) => WIDGET_COMPONENTS[w.widgetDefId]);
  const layout = renderable.map((w) => ({ i: w.id, x: w.x, y: w.y, w: w.w, h: w.h }));

  return (
    <div ref={containerRef}>
      {mounted && ready && (
        <ResponsiveGridLayout
          width={width}
          breakpoints={BREAKPOINTS}
          cols={COLS}
          layouts={{ lg: layout }}
          rowHeight={80}
          margin={[16, 16]}
          containerPadding={[0, 0]}
          onLayoutChange={(updated) => updateLayout([...updated])}
        >
          {renderable.map((w) => {
            const Component = WIDGET_COMPONENTS[w.widgetDefId];
            return (
              <div key={w.id}>
                <Component size={w.size} />
              </div>
            );
          })}
        </ResponsiveGridLayout>
      )}
    </div>
  );
}

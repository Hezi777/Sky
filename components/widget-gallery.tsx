"use client";

import { LayoutGrid, Plus, X } from "lucide-react";

import { useLayout } from "@/components/layout-provider";
import { Button } from "@/components/ui/button";
import { ScrollArea } from "@/components/ui/scroll-area";
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetHeader,
  SheetTitle,
  SheetTrigger,
} from "@/components/ui/sheet";
import { ToggleGroup, ToggleGroupItem } from "@/components/ui/toggle-group";
import { APPS, WIDGET_DEFS, type WidgetSize } from "@/lib/widgets/registry";
import { WIDGET_COMPONENTS } from "@/lib/widgets/component-map";
import { cn } from "@/lib/utils";

const SIZE_LABELS: Record<WidgetSize, string> = {
  small: "S",
  medium: "M",
  large: "L",
};

export function WidgetGallery({ triggerClassName }: { triggerClassName?: string }) {
  const { widgets, addWidget, removeWidget, setWidgetSize } = useLayout();

  const galleryDefs = WIDGET_DEFS.filter((def) => !def.locked && WIDGET_COMPONENTS[def.id]);

  return (
    <Sheet>
      <SheetTrigger
        render={
          <button
            title="Widgets"
            aria-label="Widgets"
            className={cn(
              "flex h-9 w-9 items-center justify-center rounded-lg text-muted-foreground transition-colors hover:bg-muted hover:text-foreground",
              triggerClassName,
            )}
          />
        }
      >
        <LayoutGrid className="size-[17px]" />
      </SheetTrigger>

      <SheetContent className="flex flex-col gap-0 p-0">
        <SheetHeader className="border-b">
          <SheetTitle>Widgets</SheetTitle>
          <SheetDescription>Add, remove, and resize dashboard widgets.</SheetDescription>
        </SheetHeader>

        <ScrollArea className="flex-1">
          <div className="flex flex-col gap-6 p-4">
            {APPS.map((app) => {
              const defs = galleryDefs.filter((def) => def.appId === app.id);
              if (defs.length === 0) return null;

              return (
                <div key={app.id} className="space-y-2.5">
                  <div className="flex items-center gap-2 px-1">
                    <app.icon className="size-3.5 text-muted-foreground" />
                    <p className="text-xs font-semibold uppercase tracking-[0.18em] text-muted-foreground">
                      {app.name}
                    </p>
                  </div>

                  {defs.map((def) => {
                    const instance = widgets.find((w) => w.widgetDefId === def.id);
                    const isAdded = !!instance;
                    const Icon = def.icon;

                    return (
                      <div
                        key={def.id}
                        className="flex items-start gap-3 rounded-2xl border border-border bg-muted/25 p-3"
                      >
                        <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl border border-border bg-background">
                          <Icon className="size-4" />
                        </div>

                        <div className="min-w-0 flex-1 space-y-1.5">
                          <div className="flex items-center justify-between gap-2">
                            <p className="text-sm font-medium leading-none">{def.name}</p>
                            <Button
                              variant={isAdded ? "ghost" : "secondary"}
                              size="icon-xs"
                              aria-label={isAdded ? `Remove ${def.name}` : `Add ${def.name}`}
                              onClick={() =>
                                isAdded ? removeWidget(instance.id) : addWidget(def.id)
                              }
                            >
                              {isAdded ? <X /> : <Plus />}
                            </Button>
                          </div>
                          <p className="text-xs leading-5 text-muted-foreground">
                            {def.description}
                          </p>

                          {def.availableSizes.length > 1 && (
                            <ToggleGroup
                              value={[instance?.size ?? def.defaultSize]}
                              onValueChange={(value) => {
                                if (!instance || !value[0]) return;
                                setWidgetSize(instance.id, value[0] as WidgetSize);
                              }}
                              disabled={!isAdded}
                            >
                              {def.availableSizes.map((size) => (
                                <ToggleGroupItem
                                  key={size}
                                  value={size}
                                  size="sm"
                                  aria-label={size}
                                >
                                  {SIZE_LABELS[size]}
                                </ToggleGroupItem>
                              ))}
                            </ToggleGroup>
                          )}
                        </div>
                      </div>
                    );
                  })}
                </div>
              );
            })}

            <p className="px-1 text-xs leading-5 text-muted-foreground">
              Drag and resize widgets directly on the dashboard. Changes are saved on this
              device.
            </p>
          </div>
        </ScrollArea>
      </SheetContent>
    </Sheet>
  );
}

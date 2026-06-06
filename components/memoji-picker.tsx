"use client";

import { useEffect, useRef, useState } from "react";
import { MEMOJIS } from "@/lib/memojis";

interface MemojiPickerProps {
  selectedId: string;
  onSelect: (id: string) => void;
}

export function MemojiPicker({ selectedId, onSelect }: MemojiPickerProps) {
  const [open, setOpen] = useState(false);
  const containerRef = useRef<HTMLDivElement>(null);

  // Close on outside click
  useEffect(() => {
    if (!open) return;
    function handleClick(e: MouseEvent) {
      if (
        containerRef.current &&
        !containerRef.current.contains(e.target as Node)
      ) {
        setOpen(false);
      }
    }
    document.addEventListener("mousedown", handleClick);
    return () => document.removeEventListener("mousedown", handleClick);
  }, [open]);

  return (
    <div ref={containerRef} className="relative">
      {/* Trigger — the avatar itself (rendered by parent; this button sits on top) */}
      <button
        type="button"
        onClick={() => setOpen((v) => !v)}
        aria-label="Change memoji"
        aria-expanded={open}
        className="absolute inset-0 rounded-full focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
      />

      {/* Dropdown panel */}
      {open && (
        <div
          role="dialog"
          aria-label="Pick a memoji"
          className="absolute left-1/2 top-[calc(100%+8px)] z-50 -translate-x-1/2 rounded-xl border border-border bg-popover p-3 shadow-lg"
          style={{ width: 232 }}
        >
          <p className="mb-2 text-center text-[11px] font-medium uppercase tracking-wide text-muted-foreground">
            Choose your memoji
          </p>
          <div className="grid grid-cols-6 gap-1.5">
            {MEMOJIS.map((m) => (
              <button
                key={m.id}
                type="button"
                aria-label={m.id}
                aria-pressed={m.id === selectedId}
                onClick={() => {
                  onSelect(m.id);
                  setOpen(false);
                }}
                className={[
                  "rounded-lg p-0.5 transition-colors",
                  m.id === selectedId
                    ? "ring-2 ring-primary ring-offset-1 ring-offset-popover"
                    : "hover:bg-accent",
                ].join(" ")}
              >
                <img
                  src={m.url}
                  alt={m.id}
                  width={32}
                  height={32}
                  className="h-8 w-8 rounded-full object-cover"
                  loading="lazy"
                />
              </button>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

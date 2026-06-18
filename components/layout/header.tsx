"use client";

import { useEffect, useState } from "react";
import { motion } from "framer-motion";

import { CloudAvatar } from "@/components/cloud-avatar";
import { SettingsDialog } from "@/components/settings-dialog";
import { ThemeToggle } from "@/components/theme-toggle";
import { cn } from "@/lib/utils";

function LiquidGlassFilter() {
  return (
    <svg aria-hidden="true" focusable="false" className="absolute h-0 w-0">
      <filter
        id="sky-liquid-glass"
        x="0%"
        y="0%"
        width="100%"
        height="100%"
        filterUnits="objectBoundingBox"
      >
        <feTurbulence
          type="fractalNoise"
          baseFrequency="0.001 0.005"
          numOctaves="1"
          seed="17"
          result="turbulence"
        />
        <feGaussianBlur in="turbulence" stdDeviation="3" result="softMap" />
        <feDisplacementMap
          in="SourceGraphic"
          in2="softMap"
          scale="32"
          xChannelSelector="R"
          yChannelSelector="G"
        />
      </filter>
    </svg>
  );
}

export function Header() {
  // null until mounted so server and first client render match (no hydration mismatch).
  const [now, setNow] = useState<Date | null>(null);
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    // Set on mount (not during render) so SSR and first client render match.
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setNow(new Date());
    const id = setInterval(() => setNow(new Date()), 1000);
    return () => clearInterval(id);
  }, []);

  useEffect(() => {
    function onScroll() {
      setScrolled(window.scrollY > 16);
    }

    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  const dateLabel = now
    ? now.toLocaleDateString(undefined, {
        weekday: "short",
        month: "short",
        day: "numeric",
      })
    : " ";
  const timeLabel = now
    ? now.toLocaleTimeString(undefined, {
        hour: "2-digit",
        minute: "2-digit",
      })
    : "";

  return (
    <motion.header
      initial={false}
      animate={{
        y: scrolled ? 0 : -4,
      }}
      transition={{ duration: 0.45, ease: [0.22, 1, 0.36, 1] }}
      className="pointer-events-none fixed inset-x-0 top-0 z-50 px-4 pt-3 sm:px-6"
      style={{ WebkitAppRegion: "drag" } as React.CSSProperties}
    >
      <LiquidGlassFilter />
      <div
        className={cn(
          "pointer-events-auto relative flex h-12 items-center justify-between gap-3 overflow-hidden rounded-2xl border px-2.5 transition-[border-color,box-shadow,transform] duration-700 sm:px-3",
          scrolled
            ? "border-white/30 shadow-[0_10px_24px_rgba(0,0,0,0.16),0_0_32px_rgba(0,0,0,0.08)] dark:border-white/14 dark:shadow-[0_18px_48px_rgba(0,0,0,0.38)]"
            : "border-white/18 shadow-[0_6px_18px_rgba(0,0,0,0.08)] dark:border-white/10 dark:shadow-[0_12px_36px_rgba(2,6,23,0.24)]",
        )}
        style={{
          transitionTimingFunction: "cubic-bezier(0.175, 0.885, 0.32, 2.2)",
        }}
      >
        <div
          className="absolute inset-0 z-0 [border-radius:inherit]"
          style={{
            backdropFilter: "blur(14px) saturate(1.28)",
            filter: "url(#sky-liquid-glass)",
            isolation: "isolate",
          }}
        />
        <div
          className={cn(
            "absolute inset-0 z-10 [border-radius:inherit]",
            scrolled
              ? "bg-white/32 dark:bg-[#131315]/78"
              : "bg-white/18 dark:bg-[#131315]/62",
          )}
        />
        <div
          className="absolute inset-0 z-10 bg-[radial-gradient(ellipse_at_18%_0%,rgba(59,130,246,0.22),transparent_42%),linear-gradient(90deg,rgba(30,64,175,0.10),transparent_45%,rgba(14,165,233,0.08))] opacity-80 [border-radius:inherit] dark:opacity-70"
          aria-hidden="true"
        />
        <div
          className="absolute inset-0 z-20 [border-radius:inherit] shadow-[inset_1px_1px_0_rgba(255,255,255,0.55),inset_-1px_-1px_0_rgba(255,255,255,0.20)] dark:shadow-[inset_1px_1px_0_rgba(255,255,255,0.16),inset_-1px_-1px_0_rgba(255,255,255,0.05)]"
          aria-hidden="true"
        />
        <div className="relative z-30 flex min-w-0 items-center gap-2.5">
          <CloudAvatar state="hero" size="sm" className="shrink-0" />
          <div className="min-w-0">
            <p className="text-sm font-semibold leading-none tracking-tight">
              Sky
            </p>
          </div>
        </div>

        <div className="relative z-30 flex min-w-0 items-center gap-2" style={{ WebkitAppRegion: "no-drag" } as React.CSSProperties}>
          <div
            className={cn(
              "hidden h-8 rounded-xl border px-2.5 text-xs text-muted-foreground transition-colors duration-500 sm:flex sm:items-center sm:gap-2",
              scrolled
                ? "border-white/24 bg-white/20 dark:border-white/10 dark:bg-slate-950/28"
                : "border-white/12 bg-white/10 dark:border-white/5 dark:bg-slate-950/18",
            )}
          >
            <span>{dateLabel}</span>
            <span className="h-1 w-1 rounded-full bg-muted-foreground/40" />
            <span className="tabular-nums">{timeLabel}</span>
          </div>
          <div
            className={cn(
              "flex h-8 items-center gap-0.5 rounded-xl border p-0.5 transition-colors duration-500",
              scrolled
                ? "border-white/24 bg-white/20 dark:border-white/10 dark:bg-slate-950/28"
                : "border-white/12 bg-white/10 dark:border-white/5 dark:bg-slate-950/18",
            )}
          >
            <SettingsDialog triggerClassName="h-7 w-7 rounded-lg transition-transform duration-150 hover:scale-110 active:scale-95" />
            <ThemeToggle className="h-7 w-7 rounded-lg transition-transform duration-150 hover:scale-110 active:scale-95" />
          </div>
        </div>
      </div>
    </motion.header>
  );
}

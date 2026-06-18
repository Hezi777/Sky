"use client";

import { useId } from "react";
import { cn } from "@/lib/utils";

const PRESETS = {
  subtle: {
    baseFrequency: "0.002 0.004",
    displacementScale: 12,
    blur: 12,
    saturation: 1.15,
    bgOpacity: "bg-white/[0.04] dark:bg-white/[0.03]",
    borderOpacity: "border-white/[0.08]",
    highlightOpacity: "shadow-[inset_1px_1px_0_rgba(255,255,255,0.06),inset_-1px_-1px_0_rgba(255,255,255,0.02)]",
  },
  prominent: {
    baseFrequency: "0.001 0.005",
    displacementScale: 28,
    blur: 16,
    saturation: 1.3,
    bgOpacity: "bg-white/[0.06] dark:bg-white/[0.05]",
    borderOpacity: "border-white/[0.14]",
    highlightOpacity: "shadow-[inset_1px_1px_0_rgba(255,255,255,0.14),inset_-1px_-1px_0_rgba(255,255,255,0.04)]",
  },
} as const;

interface GlassCardProps {
  children: React.ReactNode;
  intensity?: "subtle" | "prominent";
  className?: string;
}

export function GlassCard({
  children,
  intensity = "subtle",
  className,
}: GlassCardProps) {
  const id = useId();
  const filterId = `glass-${id.replace(/:/g, "")}`;
  const preset = PRESETS[intensity];

  return (
    <div
      className={cn(
        "relative overflow-hidden rounded-2xl border",
        preset.borderOpacity,
        preset.highlightOpacity,
        className,
      )}
    >
      <svg aria-hidden="true" className="absolute h-0 w-0">
        <filter
          id={filterId}
          x="0%"
          y="0%"
          width="100%"
          height="100%"
          filterUnits="objectBoundingBox"
        >
          <feTurbulence
            type="fractalNoise"
            baseFrequency={preset.baseFrequency}
            numOctaves={1}
            seed={17}
            result="turbulence"
          />
          <feGaussianBlur in="turbulence" stdDeviation="3" result="softMap" />
          <feDisplacementMap
            in="SourceGraphic"
            in2="softMap"
            scale={preset.displacementScale}
            xChannelSelector="R"
            yChannelSelector="G"
          />
        </filter>
      </svg>

      <div
        className={cn(
          "absolute inset-0 z-0 [border-radius:inherit]",
          preset.bgOpacity,
        )}
        style={{
          backdropFilter: `blur(${preset.blur}px) saturate(${preset.saturation})`,
          filter: `url(#${filterId})`,
        }}
      />

      <div className="relative z-10">{children}</div>
    </div>
  );
}

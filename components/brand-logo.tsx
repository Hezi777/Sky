import { cn } from "@/lib/utils";

// Brand logos served from /public. `darkInvert` flips monochrome-black marks
// (e.g. GitHub) to white in dark mode; colored logos render as-is.
const LOGOS: Record<string, { src: string; darkInvert?: boolean }> = {
  github: { src: "/github.svg", darkInvert: true },
  googleCalendar: { src: "/google-calendar-2026.svg" },
  ticktick: { src: "/icons8-tick-tick.svg" },
  ibkr: { src: "/Interactive_Brokers_idQBJVha2q_0.svg" },
};

export function BrandLogo({
  name,
  className,
}: {
  name: keyof typeof LOGOS;
  className?: string;
}) {
  const logo = LOGOS[name];
  return (
    // eslint-disable-next-line @next/next/no-img-element
    <img
      src={logo.src}
      alt=""
      aria-hidden
      className={cn("object-contain", logo.darkInvert && "dark:invert", className)}
    />
  );
}

import { cn } from "@/lib/utils";

// Brand logos served from /public. `darkInvert` flips monochrome-black marks
// (e.g. GitHub) to white in dark mode; colored logos render as-is.
const LOGOS: Record<string, { src: string; darkInvert?: boolean }> = {
  github: { src: "/github.svg", darkInvert: true },
  googleCalendar: { src: "/google-calendar.svg" },
  ticktick: { src: "/ticktick.svg" },
  ibkr: { src: "/ibkr.svg" },
  fair: { src: "/fair.svg" },
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

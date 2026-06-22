import { cn } from "@/lib/utils";

// Brand logos served from /public/assets/integrations. `darkInvert` flips monochrome-black marks
// (e.g. GitHub) to white in dark mode; colored logos render as-is.
const LOGOS: Record<string, { src: string; darkInvert?: boolean }> = {
  github: { src: "/assets/integrations/github.svg", darkInvert: true },
  googleCalendar: { src: "/assets/integrations/google-calendar.svg" },
  ticktick: { src: "/assets/integrations/ticktick.svg" },
  ibkr: { src: "/assets/integrations/ibkr.svg" },
  fair: { src: "/assets/integrations/fair.svg" },
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

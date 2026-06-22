"use client";

import { Icon } from "@iconify/react";
import moonIcon from "@iconify-icons/ci/moon";
import sunIcon from "@iconify-icons/ci/sun";
import { useTheme } from "next-themes";

import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";

export function ThemeToggle({ className }: { className?: string }) {
  const { setTheme, resolvedTheme } = useTheme();

  return (
    <Button
      variant="ghost"
      size="icon"
      aria-label="Toggle theme"
      onClick={() => setTheme(resolvedTheme === "dark" ? "light" : "dark")}
      className={cn("text-muted-foreground hover:text-foreground", className)}
    >
      {/* CSS-driven swap avoids a hydration flash before the theme resolves */}
      <Icon icon={sunIcon} className="hidden size-[18px] dark:block" />
      <Icon icon={moonIcon} className="block size-[18px] dark:hidden" />
    </Button>
  );
}

import type { Metadata } from "next";
import "./globals.css";

import { BottomBar } from "@/components/bottom-bar";
import { SettingsProvider } from "@/components/settings-provider";
import { ThemeProvider } from "@/components/theme-provider";
import { Toaster } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";

export const metadata: Metadata = {
  title: "Sky — Personal Dashboard",
  description: "Hen's live morning dashboard.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="en"
      suppressHydrationWarning
      className="h-full overflow-y-auto antialiased"
    >
      <body className="min-h-full overflow-y-auto">
        <ThemeProvider
          attribute="class"
          defaultTheme="system"
          enableSystem
          disableTransitionOnChange
        >
          <SettingsProvider>
            <TooltipProvider>
              <div className="min-h-screen">
                <div
                  className="fixed inset-x-0 top-0 z-40 h-8"
                  style={{ WebkitAppRegion: "drag" } as React.CSSProperties}
                />
                <main className="px-4 pb-8 sm:px-6">
                  {children}
                </main>
                <BottomBar />
              </div>
            </TooltipProvider>
          </SettingsProvider>
          <Toaster richColors position="top-right" />
        </ThemeProvider>
      </body>
    </html>
  );
}

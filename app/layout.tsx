import type { Metadata } from "next";
import "./globals.css";

import { Header } from "@/components/layout/header";
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
      className="h-full antialiased"
    >
      <body className="min-h-full">
        <ThemeProvider
          attribute="class"
          defaultTheme="system"
          enableSystem
          disableTransitionOnChange
        >
          <SettingsProvider>
            <TooltipProvider>
              <div className="min-h-screen">
                <Header />
                <main className="px-4 pb-4 pt-20 sm:px-6 sm:pb-5 sm:pt-20">
                  {children}
                </main>
              </div>
            </TooltipProvider>
          </SettingsProvider>
          <Toaster richColors position="top-right" />
        </ThemeProvider>
      </body>
    </html>
  );
}

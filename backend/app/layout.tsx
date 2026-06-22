// Minimal root layout for the headless backend. No providers, no styling —
// the API routes don't render UI. Keeps Next.js App Router satisfied.
export const metadata = {
  title: "Sky API",
  description: "Headless Next.js backend serving /api/* for Sky clients.",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}

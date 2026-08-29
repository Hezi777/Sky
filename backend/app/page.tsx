// Headless backend: this Next.js app exists only to serve the /api/* route
// handlers under app/api/. The web UI lives in native/ (the frozen legacy-web
// client was removed from the tree; it is still in git history).
// This stub keeps `next build`/`next dev` happy with a root route.
export default function Home() {
  return (
    <main>
      <h1>Sky API</h1>
      <p>Headless backend. See /api/* routes. UI client: native/.</p>
    </main>
  );
}

const base = process.env.IBKR_GATEWAY_URL || 'https://localhost:5001';
const intervalMs = Number(process.env.IBKR_KEEPALIVE_INTERVAL_MS || 60_000);
process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

async function request(path, init = {}) {
  const res = await fetch(`${base}${path}`, init);
  const text = await res.text();
  let body = null;
  try {
    body = text ? JSON.parse(text) : null;
  } catch {
    body = text;
  }
  return { ok: res.ok, status: res.status, body };
}

async function tick() {
  const status = await request('/v1/api/iserver/auth/status');
  const auth = status.body || {};

  if (auth.authenticated === true) {
    const tickle = await request('/v1/api/tickle', { method: 'POST' });
    console.log(`[${new Date().toLocaleTimeString()}] tickle ${tickle.status}`);
    return;
  }

  if (auth.connected === true) {
    const init = await request('/v1/api/iserver/auth/ssodh/init', { method: 'POST' });
    console.log(`[${new Date().toLocaleTimeString()}] ssodh/init ${init.status}`);
    return;
  }

  console.log(`[${new Date().toLocaleTimeString()}] login required (${status.status}) - open ${base}`);
}

console.log(`Keeping IBKR alive via ${base}. Press Ctrl+C to stop.`);
await tick();
setInterval(() => void tick().catch((err) => {
  console.error(`[${new Date().toLocaleTimeString()}] ${err instanceof Error ? err.message : String(err)}`);
}), intervalMs);

const base = process.env.IBKR_GATEWAY_URL || 'https://localhost:5001';

async function check(path) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 5000);
  try {
    const res = await fetch(`${base}${path}`, {
      headers: {
        Accept: 'application/json',
        'User-Agent':
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      },
      signal: controller.signal,
    });
    const text = await res.text();
    return { status: res.status, text };
  } catch (err) {
    return { error: err instanceof Error ? `${err.name}: ${err.message}` : String(err) };
  } finally {
    clearTimeout(timeout);
  }
}

process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

console.log(`IBKR gateway: ${base}`);
const sso = await check('/v1/api/iserver/auth/status');
console.log('auth/status:', JSON.stringify(sso, null, 2).slice(0, 1200));

const validate = await check('/v1/api/sso/validate');
console.log('sso/validate:', JSON.stringify(validate, null, 2).slice(0, 1200));

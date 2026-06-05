/**
 * get-google-token.mjs
 *
 * Runs a one-time Google OAuth 2.0 Authorization Code flow to obtain a refresh token
 * for Google Calendar (readonly scope).
 *
 * Redirect URI to register in the Google Cloud console:
 *   http://127.0.0.1:8889/callback
 *   (Add under: APIs & Services → Credentials → your OAuth 2.0 Client ID → Authorized redirect URIs)
 *
 * Run: node scripts/get-google-token.mjs
 */

import http from 'http';
import crypto from 'crypto';
import fs from 'fs';
import { URL, URLSearchParams } from 'url';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// ── Config ────────────────────────────────────────────────────────────────────

const PORT = 8889;
const REDIRECT_URI = `http://127.0.0.1:${PORT}/callback`;

const AUTHORIZE_URL = 'https://accounts.google.com/o/oauth2/v2/auth';
const TOKEN_URL = 'https://oauth2.googleapis.com/token';

const SCOPE = 'https://www.googleapis.com/auth/calendar.readonly';

// ── Helpers ───────────────────────────────────────────────────────────────────

function parseEnvFile(envPath) {
  if (!fs.existsSync(envPath)) return {};
  const lines = fs.readFileSync(envPath, 'utf8').split('\n');
  const env = {};
  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const idx = trimmed.indexOf('=');
    if (idx === -1) continue;
    const key = trimmed.slice(0, idx).trim();
    const val = trimmed.slice(idx + 1).trim().replace(/^["']|["']$/g, '');
    env[key] = val;
  }
  return env;
}

async function exchangeCode(code, clientId, clientSecret) {
  const body = new URLSearchParams({
    grant_type: 'authorization_code',
    code,
    redirect_uri: REDIRECT_URI,
    client_id: clientId,
    client_secret: clientSecret,
  });

  const res = await fetch(TOKEN_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: body.toString(),
  });

  const data = await res.json();
  if (!res.ok) {
    throw new Error(`Token exchange failed: ${JSON.stringify(data)}`);
  }
  return data;
}

// ── Main ──────────────────────────────────────────────────────────────────────

const envPath = path.resolve(__dirname, '../.env.local');
const env = parseEnvFile(envPath);

const clientId = env['GOOGLE_CLIENT_ID'];
const clientSecret = env['GOOGLE_CLIENT_SECRET'];

if (!clientId) {
  console.error('\nERROR: GOOGLE_CLIENT_ID is missing from .env.local\n');
  process.exit(1);
}
if (!clientSecret) {
  console.error('\nERROR: GOOGLE_CLIENT_SECRET is missing from .env.local\n');
  process.exit(1);
}

// Google requires prompt=consent to always return a refresh_token.
// access_type=offline ensures a refresh_token is included in the response.
const state = crypto.randomBytes(16).toString('hex');

const authorizeParams = new URLSearchParams({
  response_type: 'code',
  client_id: clientId,
  redirect_uri: REDIRECT_URI,
  scope: SCOPE,
  access_type: 'offline',
  prompt: 'consent',   // force consent screen so a refresh_token is always returned
  state,
});

const authorizeUrl = `${AUTHORIZE_URL}?${authorizeParams}`;

console.log('\n========================================');
console.log(' Google Calendar Refresh Token Setup');
console.log('========================================');
console.log('\nBEFORE running this script, register this redirect URI in your Google Cloud project:');
console.log('  Console: https://console.cloud.google.com/apis/credentials');
console.log('  → Your OAuth 2.0 Client ID → Authorized redirect URIs → Add URI:');
console.log(`\n  ${REDIRECT_URI}\n`);
console.log('Also ensure the Google Calendar API is enabled:');
console.log('  https://console.cloud.google.com/apis/library/calendar-json.googleapis.com\n');
console.log('Open this URL in your browser:\n');
console.log(authorizeUrl);
console.log('\nWaiting for redirect...\n');

const server = http.createServer(async (req, res) => {
  if (!req.url?.startsWith('/callback')) {
    res.writeHead(404);
    res.end('Not found');
    return;
  }

  const reqUrl = new URL(req.url, `http://127.0.0.1:${PORT}`);
  const error = reqUrl.searchParams.get('error');
  if (error) {
    res.writeHead(200, { 'Content-Type': 'text/html' });
    res.end(`<h2>Authorization failed: ${error}</h2><p>You can close this tab.</p>`);
    console.error(`\nAuthorization failed: ${error}`);
    server.close();
    return;
  }

  const returnedState = reqUrl.searchParams.get('state');
  if (returnedState !== state) {
    res.writeHead(400, { 'Content-Type': 'text/html' });
    res.end('<h2>State mismatch — possible CSRF. Try again.</h2>');
    console.error('\nState mismatch. Aborting.');
    server.close();
    return;
  }

  const code = reqUrl.searchParams.get('code');
  if (!code) {
    res.writeHead(400, { 'Content-Type': 'text/html' });
    res.end('<h2>No code in redirect. Try again.</h2>');
    server.close();
    return;
  }

  try {
    const tokens = await exchangeCode(code, clientId, clientSecret);

    res.writeHead(200, { 'Content-Type': 'text/html' });
    res.end('<h2>Success! Check your terminal for the refresh token.</h2><p>You can close this tab.</p>');

    console.log('\n========================================');
    console.log(' SUCCESS');
    console.log('========================================');
    console.log('\nRefresh token obtained. Add this line to your .env.local:\n');
    console.log(`GOOGLE_REFRESH_TOKEN=${tokens.refresh_token}`);

    if (!tokens.refresh_token) {
      console.log('\nWARNING: No refresh_token in response.');
      console.log('This happens if you previously granted access. To force a new one:');
      console.log('  1. Revoke access at https://myaccount.google.com/permissions');
      console.log('  2. Run this script again.');
    }

    console.log('\nAccess token expires in:', tokens.expires_in, 'seconds');
    console.log();
  } catch (err) {
    res.writeHead(500, { 'Content-Type': 'text/html' });
    res.end(`<h2>Token exchange failed</h2><pre>${err.message}</pre>`);
    console.error('\nToken exchange failed:', err.message);
  }

  server.close();
});

server.listen(PORT, '127.0.0.1', () => {});
server.on('close', () => process.exit(0));

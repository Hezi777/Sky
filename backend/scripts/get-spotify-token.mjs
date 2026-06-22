/**
 * get-spotify-token.mjs
 *
 * Runs a one-time Spotify Authorization Code flow (confidential client, using
 * the client secret) to obtain a NON-ROTATING refresh token.
 *
 * NOTE: We deliberately do NOT use PKCE here. PKCE-issued refresh tokens rotate
 * on every refresh (each use returns a new token and revokes the old one), which
 * breaks a stateless server that can't persist the rotated value. The
 * confidential flow (client_id + client_secret) returns a stable refresh token.
 *
 * Redirect URI to register in the Spotify dashboard:
 *   http://127.0.0.1:8888/callback
 *
 * Run: node scripts/get-spotify-token.mjs
 */

import http from 'http';
import crypto from 'crypto';
import fs from 'fs';
import { URL, URLSearchParams } from 'url';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// ── Config ────────────────────────────────────────────────────────────────────

const PORT = 8888;
const REDIRECT_URI = `http://127.0.0.1:${PORT}/callback`;

const AUTHORIZE_URL = 'https://accounts.spotify.com/authorize';
const TOKEN_URL = 'https://accounts.spotify.com/api/token';

const SCOPES = [
  'user-read-currently-playing',
  'user-read-recently-played',
  'user-read-playback-state',
].join(' ');

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

function base64urlEncode(buf) {
  return buf.toString('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');
}

function basicAuthHeader(clientId, clientSecret) {
  return 'Basic ' + Buffer.from(`${clientId}:${clientSecret}`).toString('base64');
}

async function exchangeCode(code, clientId, clientSecret) {
  const body = new URLSearchParams({
    grant_type: 'authorization_code',
    code,
    redirect_uri: REDIRECT_URI,
  });

  const res = await fetch(TOKEN_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      Authorization: basicAuthHeader(clientId, clientSecret),
    },
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

const clientId = env['SPOTIFY_CLIENT_ID'];
const clientSecret = env['SPOTIFY_CLIENT_SECRET'];
if (!clientId) {
  console.error('\nERROR: SPOTIFY_CLIENT_ID is missing from .env.local\n');
  process.exit(1);
}
if (!clientSecret) {
  console.error('\nERROR: SPOTIFY_CLIENT_SECRET is missing from .env.local\n');
  process.exit(1);
}

const state = base64urlEncode(crypto.randomBytes(16));

const authorizeParams = new URLSearchParams({
  response_type: 'code',
  client_id: clientId,
  scope: SCOPES,
  redirect_uri: REDIRECT_URI,
  state,
});

const authorizeUrl = `${AUTHORIZE_URL}?${authorizeParams}`;

console.log('\n========================================');
console.log(' Spotify Refresh Token Setup');
console.log('========================================');
console.log('\nBEFORE running this script, make sure you have registered this redirect URI');
console.log('in your Spotify app dashboard (https://developer.spotify.com/dashboard):');
console.log(`\n  ${REDIRECT_URI}\n`);
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
    console.log('\nRefresh token obtained (stable, non-rotating). Add this line to your .env.local:\n');
    console.log(`SPOTIFY_REFRESH_TOKEN=${tokens.refresh_token}`);
    console.log('\nAccess token expires in:', tokens.expires_in, 'seconds');
    console.log('Scopes granted:', tokens.scope);
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

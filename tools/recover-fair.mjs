#!/usr/bin/env node
// recover-fair.mjs — One-time recovery of the sky:fair localStorage record from
// Chrome's Default profile LevelDB.
//
// NOTE: When run on this machine (2026-06-22), the stored record contained ONLY:
//   {"fundNumber":"5140785","fundName":"Meitav","contributions":[]}
// i.e. contributions were EMPTY — no historical data to recover.
//
// Usage:
//   node tools/recover-fair.mjs                     # prints JSON to stdout
//   node tools/recover-fair.mjs --out fair.json     # writes to file
//
// Dependency-free (Node built-ins only). Best-effort latin1/utf-16 scan of
// Chrome's LevelDB .ldb/.log files — not a proper LevelDB reader.

import { readdirSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { homedir } from "node:os";
import { argv } from "node:process";

const STORAGE_KEY = "sky:fair";

// Chrome Default profile Local Storage LevelDB path (macOS)
const ldbDir = join(
  homedir(),
  "Library",
  "Application Support",
  "Google",
  "Chrome",
  "Default",
  "Local Storage",
  "leveldb"
);

function scanBuffer(buf) {
  // Try latin1 (single-byte) scan first
  const latin1 = buf.toString("latin1");
  const idx = latin1.indexOf(STORAGE_KEY);
  if (idx !== -1) {
    // The value typically follows the key after a short binary gap.
    // Scan forward for the opening '{' of the JSON object.
    const searchStart = idx + STORAGE_KEY.length;
    const jsonStart = latin1.indexOf("{", searchStart);
    if (jsonStart !== -1 && jsonStart - searchStart < 256) {
      // Find matching closing brace
      let depth = 0;
      for (let i = jsonStart; i < latin1.length; i++) {
        if (latin1[i] === "{") depth++;
        else if (latin1[i] === "}") {
          depth--;
          if (depth === 0) {
            const candidate = latin1.slice(jsonStart, i + 1);
            try {
              return JSON.parse(candidate);
            } catch {
              // not valid JSON, keep scanning
            }
          }
        }
      }
    }
  }

  // Try UTF-16LE scan (Chrome sometimes stores values as UTF-16)
  const utf16 = buf.toString("utf16le");
  const idx16 = utf16.indexOf(STORAGE_KEY);
  if (idx16 !== -1) {
    const searchStart = idx16 + STORAGE_KEY.length;
    const jsonStart = utf16.indexOf("{", searchStart);
    if (jsonStart !== -1 && jsonStart - searchStart < 256) {
      let depth = 0;
      for (let i = jsonStart; i < utf16.length; i++) {
        if (utf16[i] === "{") depth++;
        else if (utf16[i] === "}") {
          depth--;
          if (depth === 0) {
            const candidate = utf16.slice(jsonStart, i + 1);
            try {
              return JSON.parse(candidate);
            } catch {
              // continue
            }
          }
        }
      }
    }
  }

  return null;
}

function recover() {
  let files;
  try {
    files = readdirSync(ldbDir);
  } catch (err) {
    console.error(`Cannot read LevelDB directory: ${ldbDir}`);
    console.error(err.message);
    process.exit(1);
  }

  const targets = files.filter(
    (f) => f.endsWith(".ldb") || f.endsWith(".log") || f.endsWith(".sst")
  );

  for (const file of targets) {
    const buf = readFileSync(join(ldbDir, file));
    const result = scanBuffer(buf);
    if (result) return result;
  }

  return null;
}

const result = recover();

if (!result) {
  console.error("sky:fair key not found in Chrome Local Storage LevelDB.");
  process.exit(1);
}

const json = JSON.stringify(result, null, 2);

const outIdx = argv.indexOf("--out");
if (outIdx !== -1 && argv[outIdx + 1]) {
  writeFileSync(argv[outIdx + 1], json + "\n", "utf-8");
  console.error(`Written to ${argv[outIdx + 1]}`);
} else {
  console.log(json);
}

/**
 * Generates assets/icons/icon.icns and assets/icons/icon.ico from the
 * source assets in public/.
 *
 * - icon.icns is rendered from public/Mac Icon.icon (Icon Composer bundle):
 *   icon.json describes a linear-gradient squircle background with the
 *   Sky logo centered on top. Rendered with Playwright chromium at the
 *   sizes required by an .iconset, then packed with `iconutil`.
 * - icon.ico is rendered from public/logo.svg at 16/24/32/48/64/128/256 px
 *   (transparent background) and packed into a multi-image .ico manually.
 *
 * Usage: node scripts/icons/generate-icons.mjs
 * Requires: playwright (chromium) already installed in node_modules.
 *           macOS `iconutil` for the .icns step.
 */
import { chromium } from "playwright";
import { mkdirSync, rmSync, readFileSync, writeFileSync, existsSync } from "fs";
import path from "path";
import { fileURLToPath } from "url";
import { execFileSync } from "child_process";
import os from "os";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, "..", "..");
const BUILD_DIR = path.join(ROOT, "assets", "icons");
mkdirSync(BUILD_DIR, { recursive: true });

const LOGO_SVG = readFileSync(path.join(ROOT, "public", "logo.svg"), "utf8");
const ICON_JSON = JSON.parse(
  readFileSync(path.join(ROOT, "public", "Mac Icon.icon", "icon.json"), "utf8"),
);
const MAC_LOGO_SVG = readFileSync(
  path.join(ROOT, "public", "Mac Icon.icon", "Assets", "logo.svg"),
  "utf8",
);

// ── Helpers ──────────────────────────────────────────────────────────────────

function displayP3ToCss(value) {
  // value: "display-p3:r,g,b,a" -> "color(display-p3 r g b / a)"
  const [, nums] = value.split(":");
  const [r, g, b, a] = nums.split(",").map(Number);
  return `color(display-p3 ${r} ${g} ${b} / ${a})`;
}

async function renderSvgToPng(browser, html, size, outFile) {
  const ctx = await browser.newContext({
    viewport: { width: size, height: size },
    deviceScaleFactor: 1,
  });
  const page = await ctx.newPage();
  await page.setContent(html, { waitUntil: "load" });
  await page.screenshot({ path: outFile, omitBackground: true });
  await ctx.close();
}

// ── .icns ────────────────────────────────────────────────────────────────────

async function generateIcns(browser) {
  const fill = ICON_JSON.fill["linear-gradient"];
  const [from, to] = fill.map(displayP3ToCss);
  const { start, stop } = ICON_JSON.fill.orientation;
  // Approximate CSS gradient angle from start/stop points (fractions of size).
  const dx = stop.x - start.x;
  const dy = stop.y - start.y;
  const angleDeg = (Math.atan2(dx, -dy) * 180) / Math.PI; // CSS angle: 0deg = to top

  const iconsetDir = path.join(os.tmpdir(), `Sky-${Date.now()}.iconset`);
  mkdirSync(iconsetDir, { recursive: true });

  // Layer placement, derived from icon.json's `position`. The icon.json
  // canvas is 1024x1024, mapping 1:1 to points. `scale` is a multiplier on
  // the layer image's intrinsic size (its SVG viewBox), not a fraction of
  // the canvas.
  const layer = ICON_JSON.groups[0].layers[0].position;
  const viewBoxMatch = MAC_LOGO_SVG.match(/viewBox="[^"]*?\s([\d.]+)\s+([\d.]+)"/);
  const intrinsicSize = Math.max(
    Number(viewBoxMatch[1]),
    Number(viewBoxMatch[2]),
  );
  const logoSizeAt1024 = intrinsicSize * layer.scale; // e.g. 24 * 40 = 960pt
  const [txPt, tyPt] = layer["translation-in-points"];

  // macOS Big Sur+ style squircle corner radius ~ 22.37% of the canvas.
  const sizes = [
    { size: 16, name: "icon_16x16.png" },
    { size: 32, name: "icon_16x16@2x.png" },
    { size: 32, name: "icon_32x32.png" },
    { size: 64, name: "icon_32x32@2x.png" },
    { size: 128, name: "icon_128x128.png" },
    { size: 256, name: "icon_128x128@2x.png" },
    { size: 256, name: "icon_256x256.png" },
    { size: 512, name: "icon_256x256@2x.png" },
    { size: 512, name: "icon_512x512.png" },
    { size: 1024, name: "icon_512x512@2x.png" },
  ];

  for (const { size, name } of sizes) {
    const radius = size * 0.2237;
    // Scale from the 1024pt icon.json canvas to this output size.
    const px = size / 1024;
    const logoSize = logoSizeAt1024 * px;
    const tx = txPt * px;
    const ty = tyPt * px;
    const html = `
<!DOCTYPE html>
<html><head><style>
  html, body { margin: 0; padding: 0; background: transparent; }
  .canvas {
    width: ${size}px; height: ${size}px;
    position: relative;
  }
  .squircle {
    width: ${size}px; height: ${size}px;
    border-radius: ${radius}px;
    background: linear-gradient(${angleDeg}deg, ${from}, ${to});
    position: absolute; inset: 0;
    overflow: hidden;
  }
  .logo-wrap {
    position: absolute;
    inset: 0;
    display: flex;
    align-items: center;
    justify-content: center;
    overflow: visible;
    transform: translate(${tx}px, ${ty}px);
  }
  .logo {
    width: ${logoSize}px; height: ${logoSize}px;
    flex: none;
    filter: drop-shadow(0 ${size * 0.012}px ${size * 0.02}px rgba(0, 0, 0, 0.5));
  }
</style></head>
<body>
  <div class="canvas">
    <div class="squircle">
      <div class="logo-wrap">
        <div class="logo">${MAC_LOGO_SVG}</div>
      </div>
    </div>
  </div>
</body></html>`;
    const outFile = path.join(iconsetDir, name);
    await renderSvgToPng(browser, html, size, outFile);
    if (size === 1024) {
      writeFileSync("/tmp/sky-icon-preview2.png", readFileSync(outFile));
    }
  }

  const icnsOut = path.join(BUILD_DIR, "icon.icns");
  execFileSync("iconutil", ["-c", "icns", iconsetDir, "-o", icnsOut]);
  rmSync(iconsetDir, { recursive: true, force: true });
  console.log(`Wrote ${path.relative(ROOT, icnsOut)}`);
}

// ── .ico ─────────────────────────────────────────────────────────────────────

const ICO_SIZES = [16, 24, 32, 48, 64, 128, 256];

async function renderIcoPngs(browser) {
  const tmpDir = path.join(os.tmpdir(), `Sky-ico-${Date.now()}`);
  mkdirSync(tmpDir, { recursive: true });

  const pngBuffers = [];
  for (const size of ICO_SIZES) {
    const padding = Math.round(size * 0.06);
    const logoSize = size - padding * 2;
    const html = `
<!DOCTYPE html>
<html><head><style>
  html, body { margin: 0; padding: 0; background: transparent; }
  .canvas {
    width: ${size}px; height: ${size}px;
    display: flex; align-items: center; justify-content: center;
  }
  .logo { width: ${logoSize}px; height: ${logoSize}px; }
</style></head>
<body>
  <div class="canvas"><div class="logo">${LOGO_SVG}</div></div>
</body></html>`;
    const outFile = path.join(tmpDir, `icon-${size}.png`);
    await renderSvgToPng(browser, html, size, outFile);
    pngBuffers.push({ size, buffer: readFileSync(outFile) });
  }

  rmSync(tmpDir, { recursive: true, force: true });
  return pngBuffers;
}

function buildIco(pngBuffers) {
  const count = pngBuffers.length;
  const headerSize = 6;
  const entrySize = 16;
  const dataOffsetStart = headerSize + entrySize * count;

  const header = Buffer.alloc(headerSize);
  header.writeUInt16LE(0, 0); // reserved
  header.writeUInt16LE(1, 2); // type: 1 = icon
  header.writeUInt16LE(count, 4); // number of images

  const entries = [];
  const dataParts = [];
  let offset = dataOffsetStart;

  for (const { size, buffer } of pngBuffers) {
    const entry = Buffer.alloc(entrySize);
    entry.writeUInt8(size === 256 ? 0 : size, 0); // width (0 = 256)
    entry.writeUInt8(size === 256 ? 0 : size, 1); // height (0 = 256)
    entry.writeUInt8(0, 2); // color palette
    entry.writeUInt8(0, 3); // reserved
    entry.writeUInt16LE(1, 4); // color planes
    entry.writeUInt16LE(32, 6); // bits per pixel
    entry.writeUInt32LE(buffer.length, 8); // size of image data
    entry.writeUInt32LE(offset, 12); // offset of image data
    entries.push(entry);
    dataParts.push(buffer);
    offset += buffer.length;
  }

  return Buffer.concat([header, ...entries, ...dataParts]);
}

async function generateIco(browser) {
  const pngBuffers = await renderIcoPngs(browser);
  const ico = buildIco(pngBuffers);
  const icoOut = path.join(BUILD_DIR, "icon.ico");
  writeFileSync(icoOut, ico);
  console.log(`Wrote ${path.relative(ROOT, icoOut)}`);
}

// ── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  const browser = await chromium.launch({ headless: true });
  try {
    if (process.platform === "darwin" && existsSync("/usr/bin/iconutil")) {
      await generateIcns(browser);
    } else {
      console.warn("Skipping .icns: iconutil not available (requires macOS).");
    }
    await generateIco(browser);
  } finally {
    await browser.close();
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});

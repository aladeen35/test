// Rasterizes public/icons/icon.svg into the PNG sizes the PWA manifest
// needs, using the locally installed headless Chromium (no native deps).
// Run: npm run generate:icons
import { execFileSync } from 'node:child_process';
import { existsSync, mkdirSync, mkdtempSync, readFileSync, renameSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const iconsDir = join(root, 'public', 'icons');
mkdirSync(iconsDir, { recursive: true });

const CANDIDATES = [
  process.env.CHROME_BIN,
  '/opt/pw-browsers/chromium_headless_shell-1194/chrome-linux/headless_shell',
  '/opt/pw-browsers/chromium/chrome-linux/chrome',
  '/usr/bin/chromium',
  '/usr/bin/chromium-browser',
  '/usr/bin/google-chrome',
].filter(Boolean);

const chrome = CANDIDATES.find((p) => existsSync(p));
if (!chrome) {
  console.error('No Chromium binary found; skipping PNG icon generation (SVG icon still works).');
  process.exit(0);
}

const svg = readFileSync(join(iconsDir, 'icon.svg'), 'utf8');
const work = mkdtempSync(join(tmpdir(), 'ana-meno-icons-'));

function render(size, outName, { maskablePadding = 0 } = {}) {
  const scale = (size - maskablePadding * 2) / size;
  const html = `<!doctype html><html><head><style>
    html,body{margin:0;padding:0;width:${size}px;height:${size}px;overflow:hidden;
      background:${maskablePadding ? '#1E63C8' : 'transparent'}}
    svg{position:absolute;inset:${maskablePadding}px;width:${size - maskablePadding * 2}px;
      height:${size - maskablePadding * 2}px}
  </style></head><body>${svg.replace('<svg ', `<svg width="${size * scale}" height="${size * scale}" `)}</body></html>`;
  const htmlPath = join(work, `${outName}.html`);
  writeFileSync(htmlPath, html);
  execFileSync(chrome, [
    '--headless', '--disable-gpu', '--no-sandbox', '--hide-scrollbars',
    '--force-device-scale-factor=1', `--window-size=${size},${size}`,
    `--screenshot=${join(work, outName)}`, `file://${htmlPath}`,
  ], { stdio: 'pipe' });
  renameSync(join(work, outName), join(iconsDir, outName));
  console.log(`icons/${outName} (${size}x${size})`);
}

render(192, 'icon-192.png');
render(512, 'icon-512.png');
render(512, 'maskable-512.png', { maskablePadding: 64 });
rmSync(work, { recursive: true, force: true });

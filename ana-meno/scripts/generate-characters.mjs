// Generates the 30 character portrait SVGs + the mystery card into
// public/assets/characters/. Run: npm run generate:characters
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { renderAvatar, renderMysteryCard } from './avatar.mjs';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const outDir = join(root, 'public', 'assets', 'characters');
mkdirSync(outDir, { recursive: true });

const characters = JSON.parse(readFileSync(join(root, 'src', 'data', 'characters.json'), 'utf8'));

for (const c of characters) {
  const svg = renderAvatar(c);
  writeFileSync(join(outDir, `${c.slug}.svg`), svg);
}
writeFileSync(join(outDir, 'mystery.svg'), renderMysteryCard());

console.log(`Generated ${characters.length} character portraits + mystery card → ${outDir}`);

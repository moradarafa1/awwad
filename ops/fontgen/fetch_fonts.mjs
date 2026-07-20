// Downloads the Google-Fonts woff2 subsets for IBM Plex Sans Arabic and writes
// them under web/public/fonts/ so the site stays 100% first-party (no gstatic
// request at runtime). Also emits the matching @font-face CSS.
import fs from 'node:fs';
import path from 'node:path';

// usage: node fetch_fonts.mjs <google-fonts.css> <outDir> <Family Name> <slug>
// The family MUST be passed in. It used to be hardcoded, and running the
// script for a second family silently overwrote the first family's files with
// the second family's bytes under the first family's names (hit 2026-07-20).
const cssPath = process.argv[2];
const outDir = process.argv[3];
const family = process.argv[4];
const slug = process.argv[5];
if (!family || !slug) {
  console.error('usage: fetch_fonts.mjs <css> <outDir> "<Family Name>" <file-slug>');
  process.exit(1);
}
const css = fs.readFileSync(cssPath, 'utf8');
fs.mkdirSync(outDir, { recursive: true });

const blocks = [...css.matchAll(/\/\* (\S+) \*\/\s*@font-face \{([\s\S]*?)\}/g)];
const local = [];
let total = 0;

for (const [, subset, body] of blocks) {
  if (subset === 'cyrillic-ext') continue;
  const w = /font-weight: (\d+)/.exec(body)[1];
  const url = /url\((\S+?)\)/.exec(body)[1];
  const ur = /unicode-range: ([^;]+);/.exec(body)[1];
  const name = `${slug}-${subset}-${w}.woff2`;
  const res = await fetch(url, { headers: { 'User-Agent': 'Mozilla/5.0 Chrome/126' } });
  if (!res.ok) throw new Error(`${name}: HTTP ${res.status}`);
  const buf = Buffer.from(await res.arrayBuffer());
  if (buf.subarray(0, 4).toString('latin1') !== 'wOF2') throw new Error(`${name}: not a woff2`);
  fs.writeFileSync(path.join(outDir, name), buf);
  total += buf.length;
  local.push({ subset, w, name, ur, size: buf.length });
  console.log(`${name.padEnd(44)} ${buf.length.toString().padStart(7)} bytes`);
}

console.log(`TOTAL ${total} bytes across ${local.length} files`);

const cssOut = local.map(({ w, name, ur }) => `      @font-face {
        font-family: '${family}';
        font-style: normal;
        font-weight: ${w};
        font-display: swap;
        src: url('/fonts/${name}') format('woff2');
        unicode-range: ${ur};
      }`).join('\n');
fs.writeFileSync(path.join(outDir, '..', '..', '..', 'ops', `fontface.${slug}.generated.css`), cssOut);
console.log('wrote ops/fontface.generated.css');

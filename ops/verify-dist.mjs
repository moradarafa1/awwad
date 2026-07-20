// Pre-deploy gate for web/dist. Run it BEFORE every deploy:
//     node ops/verify-dist.mjs
//
// It exists because a REVIEW build is byte-for-byte deployable and looks
// completely normal. On 2026-07-20 a review build baked
// PUBLIC_WEB_APP_URL=http://localhost:8099/ into every «جرّب إصدار الويب»
// button AND into llms.txt. Nothing would have caught that before the site was
// live and every visitor hit a dead link.
//
// Exits non-zero on any failure, so it can gate a deploy script.
import fs from 'node:fs';
import path from 'node:path';

const DIST = 'D:/Claude/awwad/web/dist';
const failures = [];
const notes = [];

function walk(dir, exts) {
  const out = [];
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) out.push(...walk(p, exts));
    else if (exts.some((x) => e.name.endsWith(x))) out.push(p);
  }
  return out;
}

if (!fs.existsSync(DIST)) {
  console.error('FAIL  web/dist does not exist. Run the build first.');
  process.exit(1);
}

const textFiles = walk(DIST, ['.html', '.txt', '.xml', '.js', '.json']);
const htmlFiles = textFiles.filter((f) => f.endsWith('.html'));

// 1. A review build must never reach production.
const localhost = textFiles.filter((f) =>
  fs.readFileSync(f, 'utf8').includes('localhost'));
if (localhost.length) {
  failures.push(
    `${localhost.length} file(s) contain "localhost" - this is a REVIEW build.\n` +
    `      Rebuild WITHOUT the override:  npm --prefix web run build\n` +
    `      e.g. ${path.relative(DIST, localhost[0])}`);
}

// 2. House rule: no em-dash in user-facing text.
const emDash = htmlFiles.filter((f) => fs.readFileSync(f, 'utf8').includes('—'));
if (emDash.length) {
  failures.push(`${emDash.length} page(s) contain an em-dash: ` +
    emDash.slice(0, 3).map((f) => path.relative(DIST, f)).join(', '));
}

// 3. The cookie-free / first-party claim must stay true.
const thirdParty = /fonts\.googleapis\.com|fonts\.gstatic\.com|cdn\.jsdelivr|unpkg\.com|googletagmanager/;
const external = htmlFiles.filter((f) => thirdParty.test(fs.readFileSync(f, 'utf8')));
if (external.length) {
  failures.push(`${external.length} page(s) reference a third-party host: ` +
    external.slice(0, 3).map((f) => path.relative(DIST, f)).join(', '));
}

// 4. Artefacts that must exist.
for (const required of ['llms.txt', 'robots.txt', 'sitemap-index.xml', 'index.html']) {
  if (!fs.existsSync(path.join(DIST, required))) {
    failures.push(`missing ${required}`);
  }
}

// 5. Self-hosted fonts must actually be present, not just referenced.
const fontsDir = path.join(DIST, 'fonts');
if (fs.existsSync(fontsDir)) {
  const woff2 = fs.readdirSync(fontsDir).filter((f) => f.endsWith('.woff2'));
  if (woff2.length < 8) failures.push(`only ${woff2.length} woff2 files in dist/fonts`);
  else notes.push(`${woff2.length} self-hosted font files`);
} else {
  failures.push('dist/fonts is missing');
}

notes.push(`${htmlFiles.length} html pages`);

for (const n of notes) console.log(`ok    ${n}`);
if (!failures.length) {
  console.log('\nPASS  web/dist is safe to deploy.');
  process.exit(0);
}
console.error('');
for (const f of failures) console.error(`FAIL  ${f}`);
console.error(`\n${failures.length} problem(s). Do NOT deploy this build.`);
process.exit(1);

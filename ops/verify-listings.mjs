// Checks docs/store/STORE_LISTINGS.md against the ACTUAL store limits before
// anyone pastes it into a console. A listing that is one character over is
// rejected at submission, after the upload, which is the worst moment to find
// out. The file also carries its own claimed counts (e.g. "26/30"); those are
// verified too, because a stale claim is how a real overflow hides.
//
//   node ops/verify-listings.mjs
import fs from 'node:fs';

const SRC = 'D:/Claude/awwad/docs/store/STORE_LISTINGS.md';
const md = fs.readFileSync(SRC, 'utf8');

// Store limits, 2026. Play counts UTF-16 code units; Arabic is BMP so length
// is the same, but emoji outside the BMP count as 2. [...str] would undercount
// exactly where the description uses emoji headers, so .length is correct here.
// Matched EXACTLY, never by substring: 'Description courte' (Play short
// description, 80) contains 'Description' (App Store description, 4000), so a
// substring match reported the wrong limit for it.
const LIMITS = {
  // Play, Arabic
  'اسم التطبيق': 30, 'الوصف المختصر': 80, 'الوصف الكامل': 4000,
  // App Store, Arabic
  'الاسم': 30, 'العنوان الفرعي': 30, 'حقل الكلمات المفتاحية': 100,
  'النص الترويجي': 170, 'الوصف': 4000,
  // Play, English
  'Title': 30, 'Short description': 80, 'Full description': 4000,
  // App Store, English
  'Name': 30, 'Subtitle': 30, 'Keywords': 100,
  'Promotional text': 170, 'Description': 4000,
  // Play, French
  'Titre': 30, 'Description courte': 80, 'Description complète': 4000,
  // App Store, French
  'Nom': 30, 'Sous-titre': 30, 'Mots-clés': 100, 'Texte promotionnel': 170,
};

const problems = [];
const checked = [];

// Lines of the form:  - **<label>** (<claimed>/<limit>):
const claimRe = /^-\s+\*\*([^*]+?)\*\*\s*\((\d+)\/(\d+)\):/gm;
let m;
while ((m = claimRe.exec(md)) !== null) {
  const [, rawLabel, claimedStr, limitStr] = m;
  const label = rawLabel.trim();
  const claimed = Number(claimedStr);
  const limit = Number(limitStr);

  // The value is either a backticked one-liner or a fenced block after it.
  const after = md.slice(m.index + m[0].length);
  let value = null;
  const tick = /^\s*`([^`]+)`/.exec(after);
  const fence = /^\s*```\n([\s\S]*?)\n```/.exec(after);
  if (tick) value = tick[1];
  else if (fence) value = fence[1];
  if (value === null) { problems.push(`${label}: could not read its value`); continue; }

  const actual = value.length;
  const knownLimit = LIMITS[label];

  if (knownLimit && limit !== knownLimit) {
    problems.push(`${label}: the file says the limit is ${limit}, the store limit is ${knownLimit}`);
  }
  if (actual > limit) {
    problems.push(`${label}: ${actual} chars OVER the ${limit} limit by ${actual - limit}`);
  } else if (actual !== claimed) {
    problems.push(`${label}: claims ${claimed} chars but is actually ${actual} (limit ${limit})`);
  } else {
    checked.push(`${label.padEnd(22)} ${String(actual).padStart(4)}/${limit}`);
  }
}

// House rule, and it matters more here than anywhere: this text is pasted into
// a store console and cannot be silently fixed later.
const emDashLines = md.split('\n')
  .map((l, i) => [i + 1, l])
  .filter(([, l]) => l.includes('—'));
if (emDashLines.length) {
  problems.push(`em-dash on ${emDashLines.length} line(s), first at line ${emDashLines[0][0]}`);
}

// A listing that promises a store link before the app is published is a dead
// link on day one.
for (const dead of ['play.google.com/store/apps/details', 'apps.apple.com/app']) {
  if (md.includes(dead)) {
    problems.push(`contains a store URL (${dead}) that 404s until the app is actually published`);
  }
}

if (!checked.length) problems.push('no length-claim lines found at all; has the format changed?');

for (const c of checked) console.log(`ok    ${c}`);
if (!problems.length) {
  console.log(`\nPASS  ${checked.length} field(s) within limits.`);
  process.exit(0);
}
console.error('');
for (const p of problems) console.error(`FAIL  ${p}`);
console.error(`\n${problems.length} problem(s).`);
process.exit(1);

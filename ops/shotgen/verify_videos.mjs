// Mechanical verification for curated scholar videos (MANDATE_PLAN CU11).
// A suggested video that 404s, is private, or runs over the owner's limit is
// worse than no card at all, so every candidate id is checked against
// YouTube itself before it may enter kHabitVideos.
//
// Usage:  node ops/shotgen/verify_videos.mjs <ids.json>
// where ids.json is [{habit, id, title, scholar, maxMinutes?}, ...]
// Prints a PASS/FAIL table and writes verified.json with real durations.

import fs from 'node:fs';

const IN = process.argv[2];
if (!IN) {
  console.error('usage: node verify_videos.mjs <ids.json>');
  process.exit(2);
}
const candidates = JSON.parse(fs.readFileSync(IN, 'utf8'));

/// oEmbed answers 200 only for a video that exists AND is publicly embeddable.
async function oembed(id) {
  const r = await fetch(
    `https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=${id}&format=json`);
  if (!r.ok) return null;
  return r.json();
}

/// lengthSeconds is in the watch page's player payload. No API key needed.
async function duration(id) {
  const r = await fetch(`https://www.youtube.com/watch?v=${id}`, {
    headers: { 'user-agent': 'Mozilla/5.0', 'accept-language': 'ar,en' },
  });
  if (!r.ok) return null;
  const html = await r.text();
  const m = html.match(/"lengthSeconds":"(\d+)"/);
  return m ? parseInt(m[1], 10) : null;
}

const out = [];
for (const c of candidates) {
  const limit = (c.maxMinutes ?? 30) * 60;
  let verdict = 'FAIL', secs = null, realTitle = null, realAuthor = null;
  try {
    const meta = await oembed(c.id);
    if (!meta) {
      verdict = 'FAIL (not found / not embeddable)';
    } else {
      realTitle = meta.title;
      realAuthor = meta.author_name;
      secs = await duration(c.id);
      if (secs == null) verdict = 'FAIL (no duration)';
      else if (secs > limit) verdict = `FAIL (${Math.round(secs / 60)} min > ${c.maxMinutes ?? 30})`;
      else verdict = 'PASS';
    }
  } catch (e) {
    verdict = `FAIL (${e.message})`;
  }
  const mins = secs == null ? '?' : Math.round(secs / 60);
  console.log(
    `${verdict.startsWith('PASS') ? 'PASS' : 'FAIL'}  ${c.habit.padEnd(20)} ${c.id}  ${String(mins).padStart(3)}m  ${verdict.startsWith('PASS') ? '' : verdict}`);
  if (realTitle) console.log(`      actual: "${realTitle}" by ${realAuthor}`);
  if (verdict === 'PASS') {
    out.push({ ...c, seconds: secs, verifiedTitle: realTitle, verifiedAuthor: realAuthor });
  }
}

fs.writeFileSync('verified.json', JSON.stringify(out, null, 1));
console.log(`\n${out.length}/${candidates.length} passed -> verified.json`);

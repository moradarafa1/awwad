---
name: awwad-wabl-heading-font-reminder
description: Remind the owner to send the wabl heading font file for the Awwad project
---

This is a one-time reminder the owner asked for on 2026-07-20 at 08:25 Cairo time, ten hours before this run.

Write him a SHORT message in Arabic (Modern Standard, no em-dash, and start every line with an Arabic word, never a Latin word, or the text garbles right-to-left).

Remind him of exactly this:

He promised to send the «وبل» heading font file for the Awwad project (D:\Claude\awwad). It is needed for the MAIN HEADINGS ONLY, across three surfaces: the marketing site, the web app and the phone app. Everything else stays on IBM Plex Sans Arabic, which he confirmed he is happy with and does not want changed.

Tell him the current state so he has context:
- Main headings are currently set in Tajawal as an INTERIM placeholder. It was chosen by visually matching the title baked into wabl's «فلل وبل 13» cover photo, and corroborated by wabl.sa loading Tajawal in its own font link. It is a good guess, not a confirmation.
- Swapping it is a one-line change: `kHeadingFamily` in app/lib/app/theme.dart for the app, plus the heading rule in web/src/layouts/Base.astro for the site. The font files then go in app/assets/fonts/ and web/public/fonts/.
- Ask him to send the actual font FILE (ttf/otf/woff2), or its exact name if he only knows that.

Then ask one question: does he want the swap done as soon as he sends it, or batched with the rest of the pending phase 0.6 work.

IMPORTANT: if the font he sends is a COMMERCIAL font, do not install it without a licence. Say so plainly and ask whether he owns a licence covering app embedding and web use, because embedding an unlicensed commercial font is both a legal and a financial risk, and this project's rules forbid it. Do not silently proceed.

Also mention, in one line, that docs/PROJECT_STATE.md section 0.6 has the full up-to-date state if a new session needs to pick this up.
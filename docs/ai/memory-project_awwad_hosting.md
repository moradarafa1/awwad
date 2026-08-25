---
name: project-awwad-hosting
description: "Awwad hosting: owner's ISP blocks netlify.app, so the LIVE site+app are on GitHub Pages (moradarafa1.github.io)."
metadata: 
  node_type: memory
  type: project
  originSessionId: 91c70831-8ab0-4f0d-a4e3-dfbbd3c38854
---

**Awwad hosting (as of 2026-07-06).** The owner's ISP blocks Netlify's edge IPs at the TCP level (`*.netlify.app` unreachable from the owner's machine: `Test-NetConnection awwad-habits.netlify.app:443` = False / IP 63.176.x), while github.io / pages.dev / vercel.app / cloudflare / google all work, and api.netlify.com works (so Netlify deploys succeed but the owner can't open the sites). The Netlify sites are healthy worldwide but useless to the owner.

**LIVE, owner-reachable hosting = GitHub Pages** on the public user-page repo `github.com/moradarafa1/moradarafa1.github.io` (contains ONLY built static output; the Flutter web build ships only the public anon key, so public is safe):
- Marketing site (Astro): **https://moradarafa1.github.io/**
- Web app (Flutter web): **https://moradarafa1.github.io/app/**  (same domain = "linked together")

**How to redeploy the Pages mirror:** rebuild `web` (astro.config `site` = `https://moradarafa1.github.io`) and `app` (`flutter build web --base-href /app/`, and in Git Bash set `MSYS_NO_PATHCONV=1` or the `/app/` arg gets mangled); then assemble a staging dir = site `dist` at root + app `build/web` at `/app/` + a root `.nojekyll` (REQUIRED, else Jekyll drops Astro's `_astro/` folder) + `/app/404.html` copy of index.html for SPA; `git push` that to the github.io repo `main`. GitHub token is in the Windows cred store (`git:https://github.com`, scopes gist+repo+workflow, login moradarafa1).

Netlify (team `morad-vxjyb3y`, moradarafa.business@gmail.com) sites awwad-habits / awwad-app still exist as a global fallback. Cleaner *.pages.dev URLs would need the owner to `wrangler login` (not done). See [[project-awwad]] and `docs/PROJECT_STATE.md` §13 (2026-07-06 hosting entry).

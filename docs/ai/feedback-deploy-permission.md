---
name: feedback-deploy-permission
description: Deploy rules per target - Awwad web app and site on GitHub Pages ship continuously without asking; Android ships only at the end; Netlify still needs a per-time ask
metadata:
  node_type: memory
  type: feedback
  originSessionId: 47b3e01c-7948-49cf-abcf-6758227b498a
---

**Netlify (and any paid-quota host): ASK EVERY TIME.** On 2026-07-02 (Between
demo) the owner pushed back after several `netlify deploy --prod` runs, worried
about burning free-tier credit. Stage changes locally and deploy only when he
says so for THAT batch; an earlier "deploy when done" does not authorize a
later deploy. See [[project_between]], [[project_bloomingn]].

**GitHub Pages, Awwad site + web app: STANDING PERMISSION, granted
2026-07-20.** Deploy them with EVERY update, no asking. This is the explicit
exception to the rule above, and it is scoped to Pages, which is free.

**Awwad Android app: do NOT ship per change.** Build and publish it only after
everything else is finished. Interim APK/AAB builds are for local verification.

**Why the exception:** the owner reviews the web app himself between rounds.
Waiting for permission each time left him testing a stale deployed build while
the fixes sat unpublished locally, and he reported a bug that was already
fixed.

**How to apply:** after a verified site/web-app change, rebuild and push to
Pages in the same round. Rebuild the site WITHOUT the local review override
(`PUBLIC_WEB_APP_URL` must be unset for a real deploy, or the live «جرّب إصدار
الويب» button points at localhost), and build the app with `--base-href /app/`.
See [[project_awwad_hosting]] for the Pages layout and [[project_awwad]] for
the verify steps.

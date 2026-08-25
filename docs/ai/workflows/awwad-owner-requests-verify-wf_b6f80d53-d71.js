export const meta = {
  name: 'awwad-owner-requests-verify',
  description: 'Adversarially verify each owner request from the previous session is actually implemented in the current code',
  phases: [{ title: 'Verify' }],
}

const VERDICT = {
  type: 'object', required: ['request', 'status', 'evidence'],
  properties: {
    request: { type: 'string' },
    status: { enum: ['DONE', 'PARTIAL', 'MISSING'] },
    evidence: { type: 'string' },
    gaps: { type: 'array', items: { type: 'string' } },
    fix: { type: 'string' },
  },
}

const CTX = String.raw`PROJECT: Awwad Flutter app, D:\Claude\awwad\app (Arabic-default RTL, trilingual ar/en/fr).
The owner (an Arabic speaker, Egyptian) asked for a set of UX changes LAST session. They were
supposedly implemented but NOT yet deployed. Your job is to VERIFY the CURRENT code really does what
was asked - adversarially. Do not trust any doc or changelog; read the actual Dart source.
Report status DONE only if the code plainly does it; PARTIAL if half-done; MISSING if absent.
Quote the exact file:line evidence. If PARTIAL/MISSING, give the concrete minimal fix.
Relevant files: features/auth/auth_screen.dart, features/auth/auth_choice_screen.dart,
features/home/settings_screen.dart, features/home/profile_screen.dart,
features/home/add_habit_screen.dart, features/home/daily_log_screen.dart, core/models.dart,
core/cloud/supabase_service.dart, l10n/app_{ar,en,fr}.arb.
You may also run widget tests to prove behaviour (flutter at /d/flutter/bin/flutter.bat, run from
/d/Claude/awwad/app). If you write a temp test, DELETE it afterwards. DO NOT edit lib/ sources.`

const REQUESTS = [
  { key: 'signup-form', text: `SIGN-UP FORM: the account-creation form must read like any normal app: conventional field ORDER, the REQUIRED fields (name, email, password, gender) must come FIRST and never sit under an "optional" header; email is REQUIRED (not optional). Required fields must be marked with an ASTERISK (*) above/next to the label - NOT with the word "mandatory/اجباري". If the user submits with a required field empty, show a POPUP/TOAST notification (the conventional way), and validate the email format.` },
  { key: 'password-eye', text: `PASSWORD FIELDS: every password field must have an EYE icon that toggles password visibility (show/hide). Check ALL of them: sign-up password, sign-in password, the new-password field in the reset flow, and the change-password dialog in the profile screen.` },
  { key: 'settings-account', text: `SETTINGS - ACCOUNT ROW: when the user IS SIGNED IN, Settings must NOT ask them to "create an account / sign in"; it must show «حسابك» (Your account) and open the profile. The row must be REACTIVE (a session restored asynchronously after the first frame must still flip the row without a restart). Its POSITION must be directly UNDER the Language row and ABOVE the dark-mode row.` },
  { key: 'reset-two-step', text: `PASSWORD RESET FLOW: it must be split into TWO windows/steps: (1) enter the emailed OTP code ONLY (no password field visible), then (2) after the code verifies, a second step that ONLY asks for the new password, with an eye toggle to reveal it. The user must not see both at once. Also, after signing in successfully the app must not keep showing "create account / sign in".` },
  { key: 'savings-minutes', text: `SAVINGS CALCULATOR: the "minutes consumed daily" (دقائق مستهلكة يومياً) input must be REMOVED ENTIRELY from the app - only the money/cost-per-day field remains. Verify it is gone from the add-habit screen UI, from the savings card display, and that no UI still asks for or shows the minutes. (The data model may keep a legacy field for old records - that is acceptable ONLY if nothing in the UI collects or displays it.)` },
  { key: 'logo', text: `APP LOGO/ICON: the app icon and in-app logo must be the SEEDLING (a green sprout with two leaves, as in the owner's screenshot), consistently across: app launcher icons (android/ios), splash screen, the web app favicon/manifest, the in-app logo asset, and the marketing site favicon/logo. Verify the actual asset files and their references, and that no old logo remains referenced.` },
]

phase('Verify')
const out = await parallel(REQUESTS.map(r => () =>
  agent(`${CTX}

VERIFY THIS OWNER REQUEST:
[${r.key}] ${r.text}`, { label: `verify:${r.key}`, phase: 'Verify', schema: VERDICT })))

const res = out.filter(Boolean)
log(`verified ${res.length} owner requests; ${res.filter(r => r.status !== 'DONE').length} not fully done`)
return res

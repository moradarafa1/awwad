export const meta = {
  name: 'awwad-auth-calendar-design',
  description: 'Design specs: Supabase OTP signup/recovery flows + best-in-class habit calendar heatmap',
  phases: [{ title: 'Research' }],
}
phase('Research')
const results = await parallel([
  () => agent(`You are researching EXACT Supabase (GoTrue) + supabase_flutter v2 behavior for a Flutter app switching to email-OTP-verified signup and code-based password reset. Use ToolSearch to load the Supabase docs search tool (mcp ef4e3dc4 search_docs) and WebSearch/WebFetch as needed. Answer these precisely, citing doc pages:
1. signUp flow with "Confirm email" ON: client.auth.signUp(email, password, data) - what is returned when (a) fresh email, (b) email exists CONFIRMED (anti-enumeration obfuscated user - how exactly to detect: identities null/empty?), (c) email exists UNCONFIRMED (does it resend the confirmation email automatically?).
2. Verifying the emailed code: client.auth.verifyOTP(email, token, type) - which OtpType for signup confirmation code ({{ .Token }} in the Confirmation template)? Does it return a session?
3. Resending the signup code: client.auth.resend(...) exact signature in supabase_flutter v2 and its REST equivalent + rate limits (smtp_max_frequency default 60s?).
4. Password reset by CODE (no deep link): resetPasswordForEmail(email) -> user receives {{ .Token }} from the Recovery template -> verifyOTP(type: OtpType.recovery) -> session -> updateUser(UserAttributes(password)). Confirm this exact chain works on mobile+web without redirect URLs, and any pitfalls (PKCE interference? session state?).
5. Error codes/messages the app must map: existing-email signup, wrong/expired code, rate limit (over_email_send_rate_limit), weak password, email not confirmed on password login (and does auth.resend type signup work to re-trigger the code then?).
Return a tight spec: exact Dart calls, return shapes, error strings/codes, and numbered pitfalls. Plain text, no fluff.`, {label: 'supabase-otp-spec'}),
  () => agent(`You are designing a MONTHLY CALENDAR HEATMAP + stats block for "Awwad" (عوّاد), a trilingual (Arabic-RTL default, en, fr) Flutter habit tracker with dark AND light themes, break-habit and build-habit tracks. Study (from knowledge + web if useful) what best-in-class habit trackers do: Loop Habit Tracker, Streaks, HabitKit, Habitica - specifically their calendar/history views. Then deliver a concrete widget spec my team can implement in ONE file with no new dependencies (pure Flutter, intl available via flutter_localizations; data = list of entries {date 'yyyy-MM-dd', didSlip bool, mood, urge 0-10, resistance 0-10} for the active habit; existing stats getters: currentStreak, longestStreak, daysLogged, cleanDays):
1. Layout: month header + nav arrows (RTL-aware: which arrow goes forward in RTL?), weekday initials row (locale-aware first day of week; Arabic weeks commonly start Saturday - how to get this from MaterialLocalizations.firstDayOfWeekIndex), 5-6 row day grid, legend.
2. Day cell states + colors for BREAK track (logged clean / logged with slip / not logged / future / today ring) and BUILD track (did the habit / missed it) - give exact color roles mapping to a palette with accent teal #2dd4bf, blue #4f8ef7, amber #f59e0b, danger red, on dark bg #0d1117-ish AND light bg (WCAG-ok).
3. Stats row: which 4 numbers beat competitors (current streak, best streak, month completion %, total days?) + a small caption formula for month completion (days logged in month / days elapsed in month).
4. Interactions: tap day -> bottom sheet with that day entry (mood emoji, sliders values, note) or 'لم يسجل'; month nav bounds (habit.createdAt month .. current month).
5. Edge cases list: RTL grid direction (GridView + textDirection), month lengths, first-day offset math (give the formula), year boundaries, today marker, empty month, timezone (dates are local dayKey strings - no TZ math needed).
Return a precise implementation spec with the exact offset formula and a compact color table. Plain text.`, {label: 'calendar-design'}),
])
return { otpSpec: results[0], calendarSpec: results[1] }
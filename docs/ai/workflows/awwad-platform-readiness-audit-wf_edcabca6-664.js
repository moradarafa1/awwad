export const meta = {
  name: 'awwad-platform-readiness-audit',
  description: 'Audit every feature for Android + iOS readiness (plugins, permissions, channels, Info.plist)',
  phases: [{ title: 'Audit' }, { title: 'Verify' }],
}
const FINDINGS = {
  type: 'object', required: ['findings'],
  properties: { findings: { type: 'array', items: {
    type: 'object', required: ['platform', 'feature', 'severity', 'problem', 'fix'],
    properties: {
      platform: { enum: ['android', 'ios', 'both'] },
      feature: { type: 'string' },
      severity: { enum: ['blocker', 'major', 'minor'] },
      problem: { type: 'string' },
      fix: { type: 'string', description: 'concrete file-level fix' },
    } } } },
}
const VERDICT = {
  type: 'object', required: ['isReal', 'reason'],
  properties: { isReal: { type: 'boolean' }, reason: { type: 'string' } },
}
phase('Audit')
const DIMS = [
  { key: 'ios', prompt: `You are auditing the Awwad Flutter app (D:\\Claude\\awwad\\app) for iOS READINESS - the owner will build it on a Mac from this exact repo, so every iOS gap must be caught NOW at the code/config level. Check systematically: (1) app/ios/Runner/Info.plist - permissions/usage descriptions needed by the feature set (notifications, no camera/location used), LSApplicationQueriesSchemes for url_launcher uses (mailto: contact-us in settings_screen.dart, https YouTube links in daily_log/sos, facebook link) - canLaunchUrl on iOS returns FALSE for schemes not listed there; (2) flutter_local_notifications iOS wiring in app/lib/core/notifications/notifications_mobile.dart - DarwinInitializationSettings present? iOS permission request (requestPermissions on the iOS plugin implementation)? zonedSchedule iOS behavior; (3) every MethodChannel (awwad/dns_shield, awwad/usage_stats in MainActivity.kt) has NO iOS side - confirm the Dart layers (core/platform/dns_shield.dart, core/platform/usage_stats.dart) fail OPEN on MissingPluginException and the UIs (features/shield/dns_shield_screen.dart, features/phone/usage_screen.dart) degrade gracefully; (4) plugin iOS support sanity from pubspec.yaml (share_plus, connectivity_plus, url_launcher, shared_preferences, flutter_local_notifications, supabase_flutter+app_links, google_fonts network fetch on first run, fl_chart); (5) app/ios project config: bundle id, CFBundleLocalizations ar/en/fr, ITSAppUsesNonExemptEncryption. Report every gap with a concrete fix.` },
  { key: 'android-features', prompt: `You are auditing the Awwad Flutter app (D:\\Claude\\awwad\\app) feature-by-feature for ANDROID correctness at the code/manifest level (no device available). For EACH of these features, trace the full wiring and flag anything broken or missing: sign-up with email code + forgot-password (supabase auth calls), auto-sync on open/save, 36-habit catalog + custom habits with custom metrics, daily log (track-aware question, trigger chips, skip-day, yesterday repair), month heatmap calendar, analytics section + journey cards (recovery timeline, savings, triggers), SOS screen (timers, breathing animation), DNS shield channel (Settings.Global read - does it need any permission on Android 13+? verify), usage stats channel (AppOpsManager unsafeCheckOpNoThrow requires API 29+? MIN SDK check in build.gradle.kts vs used APIs!), notifications (POST_NOTIFICATIONS runtime permission on 13+, exact alarms NOT used, boot receiver), share_plus intent, url_launcher queries in manifest (mailto/https need <queries> entries on Android 11+ for canLaunchUrl!), Pomodoro, badges/ranks/stages. Report every gap with a concrete file-level fix.` },
]
const results = await pipeline(
  DIMS,
  d => agent(d.prompt + ' Only report REAL gaps you verified in the actual files (read them), no speculation.', {label: `audit:${d.key}`, phase: 'Audit', schema: FINDINGS}),
  (review, d) => parallel((review?.findings ?? []).map(f => () =>
    agent(`Adversarially VERIFY this platform-readiness claim by reading the actual files in D:\\Claude\\awwad\\app. Default isReal=false unless concretely traceable. Claim: [${f.platform}/${f.severity}] ${f.feature}: ${f.problem} FIX: ${f.fix}`, {label: `verify:${d.key}`, phase: 'Verify', schema: VERDICT})
      .then(v => ({...f, verdict: v}))
  ))
)
const confirmed = results.flat().filter(Boolean).filter(f => f.verdict?.isReal)
return { confirmed, totalChecked: results.flat().filter(Boolean).length }
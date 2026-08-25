export const meta = {
  name: 'awwad-readiness-audit',
  description: 'Final readiness audit of the Awwad Android release: error UX, release config, secrets hygiene, live surfaces and backend',
  phases: [
    { title: 'Audit', detail: '4 parallel read-only auditors' },
  ],
}

phase('Audit')

const SCHEMA = {
  type: 'object',
  required: ['ready', 'findings'],
  properties: {
    ready: { type: 'boolean', description: 'true if this dimension is fully ready, no critical findings' },
    findings: {
      type: 'array',
      items: {
        type: 'object',
        required: ['severity', 'summary'],
        properties: {
          severity: { type: 'string', enum: ['critical', 'warning', 'info'] },
          summary: { type: 'string' },
          evidence: { type: 'string', description: 'file:line or command output proving it' },
          fix: { type: 'string' },
        },
      },
    },
    notes: { type: 'string' },
  },
}

const COMMON = 'Project: Awwad, a trilingual (ar/en/fr) Flutter habit app at D:\\Claude\\awwad (app code in app/lib, Android config in app/android). Today is 2026-07-07. Earlier today we fixed: (1) missing android.permission.INTERNET in app/android/app/src/main/AndroidManifest.xml (Flutter only auto-adds it to debug builds, so release APK/AAB had no network), (2) Gradle daemon OOM (heap cut from -Xmx8G to -Xmx2048m in app/android/gradle.properties), (3) raw exception strings shown to users in snackbars (now mapped to localized ar/en/fr messages). Release APK + AAB were rebuilt tonight around 8:00 PM with the SUPABASE_URL / SUPABASE_ANON_KEY dart-defines. You are a READ-ONLY auditor: do NOT edit files, do NOT run flutter build or gradle commands. Return findings via the structured output schema; be strict - the goal is to catch anything NOT ready.'

const prompts = [
  {
    key: 'error-ux',
    prompt: COMMON + `

Audit dimension: USER-FACING ERROR HANDLING in app/lib.

1. Find any remaining place where a raw exception or technical string can reach the UI: grep app/lib for "e.toString()" and for dollar-sign string interpolation of a caught exception (patterns like Text with dollar-e inside), and inspect every catch block that feeds a SnackBar, dialog, or Text widget. Ignore debugPrint/print/log-only usage and code that is not user-visible.
2. Verify the three fixed files are internally consistent:
   - app/lib/features/auth/auth_screen.dart: the _friendlyError method returns _tr(key) for keys errNetwork, errBadCredentials, errEmailExists, errWeakPassword, errBadEmail, errBadOtp, errRateLimit, errEmailNotConfirmed, errGeneric. Confirm EVERY one of those keys exists in the _regStrings map for ALL THREE locales ar, en, fr (a missing key would throw at runtime because lookups use the null-assert bang operator).
   - app/lib/features/home/profile_screen.dart: uses _kAcc lookups for errNetwork and errGeneric with a bang - confirm both exist in the _kAcc map with ar/en/fr entries.
   - app/lib/features/home/settings_screen.dart: uses a _kSyncErr map with keys network and generic - confirm the map is defined (end of file), has ar/en/fr for both keys, and the file ends validly (no stray text after the closing brace).
3. Check the new Arabic error strings: must be MSA (fusha), must NOT contain the em-dash character, and must not start with a Latin word.
Report each problem as a finding with file:line evidence.`,
  },
  {
    key: 'release-config',
    prompt: COMMON + `

Audit dimension: ANDROID RELEASE CONFIGURATION AND ARTIFACTS.

1. app/android/app/src/main/AndroidManifest.xml must contain android.permission.INTERNET.
2. Run this single read-only command: 'D:\\Android\\Sdk\\build-tools\\36.0.0\\aapt.exe' dump permissions 'D:\\Claude\\awwad\\app\\build\\app\\outputs\\flutter-apk\\app-release.apk' - confirm android.permission.INTERNET is listed.
3. Confirm both artifacts exist and were modified TODAY (2026-07-07, evening): app/build/app/outputs/flutter-apk/app-release.apk and app/build/app/outputs/bundle/release/app-release.aab. Report sizes and timestamps.
4. app/android/gradle.properties: confirm org.gradle.jvmargs uses -Xmx2048m (not 8G), org.gradle.daemon.idletimeout is set, kotlin.incremental=false and kotlin.jvm.target.validation.mode=warning still present.
5. app/android/app/build.gradle.kts: release buildType signs with the release signingConfig when key.properties exists; confirm app/android/key.properties and app/android/app/upload-keystore.jks both exist on disk.
6. app/pubspec.yaml: report the version line (the store versionName+versionCode, e.g. 1.0.0+1).
7. Sanity: applicationId com.awwad.awwad, minSdk 24, targetSdk 36 - flag anything inconsistent for Play submission.
Do NOT run any build; file reads and the single aapt dump only.`,
  },
  {
    key: 'secrets',
    prompt: COMMON + `

Audit dimension: SECRETS HYGIENE AND GIT STATE. Work in D:\\Claude\\awwad (a git repo). Use git commands via Bash (read-only: ls-files, grep, status).

1. Run: git -C /d/Claude/awwad ls-files, and check that NEITHER app/android/key.properties NOR any .jks/keystore file is tracked by git. Also confirm a .gitignore (root or app/android/) covers key.properties and *.jks.
2. Search TRACKED files only for leaked secrets using git grep: (a) any actual service_role JWT value (a long token starting with eyJ that decodes to role service_role) - prose mentions of the words service_role are fine, an actual token is CRITICAL; (b) the keystore password string <KEYSTORE_PASSWORD from _local/memory-project_awwad.FULL.md> - it must appear in NO tracked file (it lives only in the gitignored key.properties).
3. The public anon key (a JWT whose payload role is anon) is shippable and allowed in ops/build-app-cloud.ps1 and docs - do not flag it.
4. Run git -C /d/Claude/awwad status --porcelain and list which files are modified/untracked right now (today's fixes are expected to be uncommitted - informational, not critical, but list them so the owner knows what needs committing).
Report findings with evidence.`,
  },
  {
    key: 'live-backend',
    prompt: COMMON + `

Audit dimension: LIVE SURFACES AND BACKEND HEALTH.

1. Use WebFetch on https://moradarafa1.github.io/ and https://moradarafa1.github.io/app/ - both must return real content (marketing site and the Flutter web app shell). Report status. Do NOT test netlify.app URLs - the owner's ISP blocks them by design; not a failure.
2. Use ToolSearch with query "select:mcp__ef4e3dc4-053a-4172-958e-7d368f201ed2__get_project,mcp__ef4e3dc4-053a-4172-958e-7d368f201ed2__get_advisors" to load the Supabase MCP tools, then:
   - get_project with id kdczbzzjezyhfxgpegqc - must be ACTIVE_HEALTHY.
   - get_advisors with type security and again with type performance for that project - report any ERROR-level advisories as critical findings, WARN-level as warnings (name + affected table/function).
3. Include one info finding: the DEPLOYED web app on GitHub Pages was built BEFORE today's localized-error-message fixes - it works, but shows raw English errors on network failure until rebuilt and redeployed.`,
  },
]

const results = await parallel(
  prompts.map((p) => () => agent(p.prompt, { label: 'audit:' + p.key, phase: 'Audit', schema: SCHEMA }))
)

return {
  audits: prompts.map((p, i) => ({ dimension: p.key, result: results[i] })),
}
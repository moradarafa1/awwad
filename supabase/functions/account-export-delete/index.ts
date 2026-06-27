// account-export-delete — GDPR / store-compliance data export and account deletion.
//
// Authenticated paths:
//   { action: 'export' } -> returns all the caller's own rows as JSON.
//   { action: 'delete' } -> hard-deletes the auth user (cascades to every table).
//
// Logged-out deletion (App Store 5.1.1(v) / Play requirement): the public
// /delete-account web page lets uninstalled users sign in via email OTP
// (supabase.auth.signInWithOtp) and then call action:'delete' — so deletion is
// reachable without remembering a password and without being permanently locked out.

import { adminClient, getUser, json, corsHeaders } from '../_shared/utils.ts';

const USER_TABLES = [
  'habits', 'onboarding_survey', 'custom_field_defs', 'custom_field_options',
  'daily_entries', 'entry_events', 'entry_selections', 'earned_badges',
  'trusted_devices', 'subscriptions', 'profiles',
];

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  try {
    const admin = adminClient();
    const user = await getUser(req, admin);
    if (!user) return json({ error: 'unauthorized' }, 401);

    const { action } = await req.json();

    if (action === 'export') {
      const out: Record<string, unknown> = { exported_at: new Date().toISOString() };
      for (const tbl of USER_TABLES) {
        const { data } = await admin.from(tbl).select('*').eq(
          tbl === 'profiles' ? 'id' : 'user_id',
          user.id,
        );
        out[tbl] = data ?? [];
      }
      return json(out);
    }

    if (action === 'delete') {
      // Deleting the auth user cascades to every user-owned table (ON DELETE CASCADE).
      // analytics_events.user_id is ON DELETE SET NULL (de-identified, no PII left).
      const { error } = await admin.auth.admin.deleteUser(user.id);
      if (error) return json({ error: error.message }, 500);
      return json({ ok: true, deleted: true });
    }

    return json({ error: 'unknown action' }, 400);
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});

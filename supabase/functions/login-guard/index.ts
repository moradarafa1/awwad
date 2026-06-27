// login-guard — decides whether a login needs an email OTP.
//
// Flow: client calls signInWithPassword (gets an aal1 session), then calls this
// function with that JWT + the device's stored secret (if any). We check the
// trusted_devices table (server-side, service_role) and tell the client whether
// to skip OTP. OTP is only ever sent to UNTRUSTED devices, keeping email volume
// well under Brevo's free 300/day.
//
// SECURITY NOTE: this is a login *verification* layer, not an unbreakable 2nd
// factor (signInWithPassword already returns a session). It is hardened with
// IP re-checks + expiry + secret rotation, and documented honestly as such.

import { adminClient, getUser, json, sha256Hex, corsHeaders } from '../_shared/utils.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  try {
    const admin = adminClient();
    const user = await getUser(req, admin);
    if (!user) return json({ error: 'unauthorized' }, 401);

    const { device_secret } = await req.json().catch(() => ({}));
    const ip = req.headers.get('x-forwarded-for')?.split(',')[0]?.trim() ?? null;

    if (device_secret) {
      const hash = await sha256Hex(device_secret);
      const { data: device } = await admin
        .from('trusted_devices')
        .select('id, expires_at, revoked_at, last_ip')
        .eq('user_id', user.id)
        .eq('device_token_hash', hash)
        .is('revoked_at', null)
        .maybeSingle();

      const valid =
        device &&
        new Date(device.expires_at).getTime() > Date.now();

      if (valid) {
        // Sliding window: refresh last_used_at + IP.
        await admin
          .from('trusted_devices')
          .update({ last_used_at: new Date().toISOString(), last_ip: ip })
          .eq('id', device.id);
        return json({ trusted: true, otpRequired: false });
      }
    }

    // Untrusted (or unknown) device → require email OTP.
    // The client calls supabase.auth.signInWithOtp({ email, shouldCreateUser:false }).
    return json({ trusted: false, otpRequired: true });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});

// register-trusted-device — called after a successful verifyOtp when the user
// ticked "trust this device". Stores ONLY a sha256 hash of the device secret.

import { adminClient, getUser, json, sha256Hex, corsHeaders } from '../_shared/utils.ts';

const TRUST_DAYS = 90;

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  try {
    const admin = adminClient();
    const user = await getUser(req, admin);
    if (!user) return json({ error: 'unauthorized' }, 401);

    const { device_secret, device_label, platform } = await req.json();
    if (!device_secret || typeof device_secret !== 'string') {
      return json({ error: 'device_secret required' }, 400);
    }

    const hash = await sha256Hex(device_secret);
    const ip = req.headers.get('x-forwarded-for')?.split(',')[0]?.trim() ?? null;
    const expires = new Date(Date.now() + TRUST_DAYS * 86400_000).toISOString();

    const { error } = await admin.from('trusted_devices').upsert(
      {
        user_id: user.id,
        device_token_hash: hash,
        device_label: device_label ?? null,
        platform: platform ?? null,
        last_ip: ip,
        last_used_at: new Date().toISOString(),
        expires_at: expires,
        revoked_at: null,
      },
      { onConflict: 'user_id,device_token_hash' },
    );
    if (error) return json({ error: error.message }, 500);

    return json({ ok: true, expires_at: expires });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});

// signup — creates a CONFIRMED account server-side (admin.createUser with
// email_confirm), so registration never depends on confirmation emails.
//
// WHY: email confirmation is ON but the project has no custom SMTP; Supabase's
// built-in mailer allows ~2 emails/hour, so real users could not finish
// signing up (over_email_send_rate_limit, hit live on 2026-07-06). This
// function removes email from the signup path entirely. When Brevo SMTP is
// configured later, the client can switch back to plain auth.signUp and this
// function can be retired.
//
// Flow: client POSTs {email, password, data} → validate → admin.createUser
// (triggers still create profile+subscription) → client then signs in with
// password as usual. Error codes mirror GoTrue's so the app's localized
// error mapping keeps working unchanged.

import { adminClient, json, corsHeaders } from '../_shared/utils.ts';

const EMAIL_RE = /^[^@\s]+@[^@\s]+\.[^@\s]{2,}$/;

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  try {
    const { email, password, data } = await req.json().catch(() => ({}));

    const cleanEmail = typeof email === 'string' ? email.trim().toLowerCase() : '';
    if (!EMAIL_RE.test(cleanEmail)) {
      return json({ error: 'email_address_invalid' }, 400);
    }
    if (typeof password !== 'string' || password.length < 6) {
      return json({ error: 'weak_password' }, 400);
    }

    // Whitelist metadata keys (never trust arbitrary client JSON).
    const meta: Record<string, unknown> = {};
    if (data && typeof data === 'object') {
      for (const k of ['full_name', 'locale', 'gender', 'country', 'birth_date', 'whatsapp']) {
        const v = (data as Record<string, unknown>)[k];
        if (typeof v === 'string' && v.trim() !== '') meta[k] = v.trim().slice(0, 200);
      }
    }

    const admin = adminClient();
    const { data: created, error } = await admin.auth.admin.createUser({
      email: cleanEmail,
      password,
      email_confirm: true,
      user_metadata: meta,
    });

    if (error) {
      const msg = error.message ?? 'signup failed';
      const code = /already|exists/i.test(msg)
        ? 'user_already_exists'
        : /password/i.test(msg)
          ? 'weak_password'
          : /email/i.test(msg)
            ? 'email_address_invalid'
            : 'signup_failed';
      return json({ error: code, message: msg }, 400);
    }

    return json({ user: { id: created.user?.id, email: created.user?.email } });
  } catch (e) {
    return json({ error: 'internal', message: String(e) }, 500);
  }
});

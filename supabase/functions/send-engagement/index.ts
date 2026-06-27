// send-engagement — retention funnel sender (invoked by cron, not end users).
//
// Picks users due for a nudge and sends a push via FCM, RESPECTING PRAYER TIMES
// (no notification is sent within a configurable window around each prayer).
//
// P4 prerequisites (not in P1): a `device_tokens` table (user_id, fcm_token,
// platform, tz) populated by the Flutter client, and the FCM server credentials
// in env (FCM_PROJECT_ID, FCM_SERVICE_ACCOUNT). Until then this runs as a safe
// no-op that reports what it *would* send.

import { adminClient, json, corsHeaders } from '../_shared/utils.ts';

// Rough prayer-time guard (local hour windows). Replace with a proper
// per-location prayer-time calc (e.g. Aladhan API cached per city) in P4.
function isNearPrayerTime(localHour: number): boolean {
  const prayerHours = [5, 12, 15, 18, 20]; // fajr, dhuhr, asr, maghrib, isha (approx)
  return prayerHours.some((h) => Math.abs(localHour - h) < 1);
}

interface Plan { type: string; user_id: string }

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  try {
    const admin = adminClient();
    const { kind } = await req.json().catch(() => ({ kind: 'daily' }));

    // Example targeting: users whose last entry is getting stale (streak at risk)
    // or who haven't logged today. This is a skeleton; refine queries in P4.
    const planned: Plan[] = [];
    const { data: habits } = await admin
      .from('habits')
      .select('user_id, last_entry_date, current_streak')
      .eq('status', 'active');

    const today = new Date().toISOString().slice(0, 10);
    for (const h of habits ?? []) {
      if (h.last_entry_date !== today) {
        planned.push({
          type: h.current_streak > 0 ? 'streak_risk' : 'daily',
          user_id: h.user_id,
        });
      }
    }

    // FCM send is intentionally not wired until device_tokens + FCM creds exist.
    // const tokens = await admin.from('device_tokens').select(...)
    // for each token where !isNearPrayerTime(localHour): sendFcm(token, message)

    return json({
      kind,
      planned_count: planned.length,
      note: 'P1 skeleton — FCM send wired in P4 once device_tokens + FCM creds exist.',
      prayer_guard_example: isNearPrayerTime(new Date().getUTCHours()),
    });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});

// award-badges — server-side badge re-validation after a daily entry is saved.
// Recomputes the streak from daily_entries (trusted server math) and awards any
// newly-earned badges via the award_badge() SECURITY DEFINER routine. Prevents
// clients from self-granting badges.

import { adminClient, getUser, json, corsHeaders } from '../_shared/utils.ts';

interface Entry { entry_date: string; did_slip: boolean }

function computeStreak(entries: Entry[]): number {
  // entries sorted by date desc; count consecutive non-slip from the top.
  let s = 0;
  for (const e of entries) {
    if (!e.did_slip) s++;
    else break;
  }
  return s;
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  try {
    const admin = adminClient();
    const user = await getUser(req, admin);
    if (!user) return json({ error: 'unauthorized' }, 401);

    const { habit_id } = await req.json();
    if (!habit_id) return json({ error: 'habit_id required' }, 400);

    // Confirm the habit belongs to the user.
    const { data: habit } = await admin
      .from('habits')
      .select('id')
      .eq('id', habit_id)
      .eq('user_id', user.id)
      .maybeSingle();
    if (!habit) return json({ error: 'forbidden' }, 403);

    const { data: entries } = await admin
      .from('daily_entries')
      .select('entry_date, did_slip')
      .eq('user_id', user.id)
      .eq('habit_id', habit_id)
      .eq('is_deleted', false)
      .order('entry_date', { ascending: false });

    const rows = (entries ?? []) as Entry[];
    const streak = computeStreak(rows);
    const daysLogged = rows.length;

    const { data: defs } = await admin
      .from('badge_definitions')
      .select('key, criteria_type, threshold')
      .eq('is_active', true);

    const qualified: string[] = [];
    for (const d of defs ?? []) {
      if (d.criteria_type === 'first_log' && daysLogged >= 1) qualified.push(d.key);
      else if (d.criteria_type === 'streak_clean_days' && streak >= (d.threshold ?? 1e9)) qualified.push(d.key);
      else if (d.criteria_type === 'days_logged' && daysLogged >= (d.threshold ?? 1e9)) qualified.push(d.key);
    }

    const newly: string[] = [];
    for (const key of qualified) {
      const { data: existing } = await admin
        .from('earned_badges')
        .select('id')
        .eq('user_id', user.id)
        .eq('badge_key', key)
        .eq('habit_id', habit_id)
        .maybeSingle();
      if (!existing) {
        await admin.rpc('award_badge', {
          p_user_id: user.id,
          p_habit_id: habit_id,
          p_badge_key: key,
          p_streak: streak,
        });
        newly.push(key);
      }
    }

    return json({ streak, days_logged: daysLogged, newly_earned: newly });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});

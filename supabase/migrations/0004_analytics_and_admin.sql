-- ============================================================
-- 0004 — Analytics events (first-party) + admin aggregate RPCs.
-- analytics_events is insert-only and never read back by clients;
-- all reads happen through SECURITY DEFINER admin RPCs gated by is_admin().
-- ============================================================

create table public.analytics_events (
  id          bigint generated always as identity primary key,
  user_id     uuid references auth.users(id) on delete set null,
  event_name  text not null,
  props       jsonb not null default '{}'::jsonb,    -- allow-listed, NO PII
  platform    text,
  app_version text,
  occurred_at timestamptz not null default now(),
  day         date generated always as ((occurred_at at time zone 'UTC')::date) stored
);
alter table public.analytics_events enable row level security;

-- A user can only log events as themselves (or anonymous before auth).
create policy analytics_insert_self on public.analytics_events
  for insert with check (user_id is null or auth.uid() = user_id);
-- NO select/update/delete policy for clients at all.

create index idx_analytics_event_day on public.analytics_events(event_name, day);
create index idx_analytics_day on public.analytics_events(day);

-- ------------------------------------------------------------
-- Admin RPCs — every one is gated by is_admin(); none expose
-- another user's identity unless the owner explicitly drills down
-- into consented research data (admin_survey_individual).
-- ------------------------------------------------------------

create or replace function public.admin_overview()
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare result jsonb;
begin
  if not public.is_admin() then raise exception 'forbidden'; end if;

  select jsonb_build_object(
    'total_users',     (select count(*) from public.profiles),
    'total_habits',    (select count(*) from public.habits where not is_deleted),
    'active_today',    (select count(distinct user_id) from public.analytics_events
                         where day = (now() at time zone 'UTC')::date),
    'active_7d',       (select count(distinct user_id) from public.analytics_events
                         where day >= (now() at time zone 'UTC')::date - 6),
    'entries_total',   (select count(*) from public.daily_entries where not is_deleted),
    'avg_streak',      (select coalesce(round(avg(current_streak),1),0) from public.habits where status='active'),
    'badges_awarded',  (select count(*) from public.earned_badges)
  ) into result;
  return result;
end;
$$;

create or replace function public.admin_daily_active(p_days int default 30)
returns table(day date, active int)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select e.day, count(distinct e.user_id)::int as active
  from public.analytics_events e
  where public.is_admin()
    and e.day >= (now() at time zone 'UTC')::date - (p_days - 1)
  group by e.day order by e.day;
$$;

create or replace function public.admin_track_split()
returns table(track text, habits int, users int)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select h.track, count(*)::int, count(distinct h.user_id)::int
  from public.habits h
  where public.is_admin() and not h.is_deleted
  group by h.track;
$$;

create or replace function public.admin_top_habits(p_limit int default 20)
returns table(catalog_key text, title jsonb, picks int, is_islamic boolean)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select c.key, c.title, count(h.id)::int as picks, c.is_islamic
  from public.habits h
  join public.habit_catalog c on c.id = h.catalog_id
  where public.is_admin() and not h.is_deleted
  group by c.key, c.title, c.is_islamic
  order by picks desc
  limit p_limit;
$$;

create or replace function public.admin_badge_distribution()
returns table(badge_key text, tier text, earned int)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select b.key, b.tier, count(e.id)::int as earned
  from public.badge_definitions b
  left join public.earned_badges e on e.badge_key = b.key
  where public.is_admin()
  group by b.key, b.tier order by earned desc;
$$;

-- Aggregate demographics from consented surveys (no identity).
create or replace function public.admin_survey_aggregate()
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare result jsonb;
begin
  if not public.is_admin() then raise exception 'forbidden'; end if;
  select jsonb_build_object(
    'responses',   (select count(*) from public.onboarding_survey where consent),
    'by_age',      (select coalesce(jsonb_object_agg(age_range, c),'{}') from
                     (select age_range, count(*) c from public.onboarding_survey
                      where consent and age_range is not null group by age_range) t),
    'by_gender',   (select coalesce(jsonb_object_agg(gender, c),'{}') from
                     (select gender, count(*) c from public.onboarding_survey
                      where consent and gender is not null group by gender) t),
    'by_country',  (select coalesce(jsonb_object_agg(country, c),'{}') from
                     (select country, count(*) c from public.onboarding_survey
                      where consent and country is not null group by country) t),
    'by_referral', (select coalesce(jsonb_object_agg(referral_source, c),'{}') from
                     (select referral_source, count(*) c from public.onboarding_survey
                      where consent and referral_source is not null group by referral_source) t)
  ) into result;
  return result;
end;
$$;

-- Owner-only drill-down into individual consented research rows.
create or replace function public.admin_survey_individual(p_limit int default 100, p_offset int default 0)
returns setof public.onboarding_survey
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select * from public.onboarding_survey
  where public.is_admin() and consent
  order by created_at desc
  limit p_limit offset p_offset;
$$;

-- Lock down execution to authenticated (the is_admin() check inside does the real gating).
revoke all on function
  public.admin_overview(), public.admin_daily_active(int), public.admin_track_split(),
  public.admin_top_habits(int), public.admin_badge_distribution(),
  public.admin_survey_aggregate(), public.admin_survey_individual(int,int)
from public;
grant execute on function
  public.admin_overview(), public.admin_daily_active(int), public.admin_track_split(),
  public.admin_top_habits(int), public.admin_badge_distribution(),
  public.admin_survey_aggregate(), public.admin_survey_individual(int,int)
to authenticated;

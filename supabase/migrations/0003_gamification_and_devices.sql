-- ============================================================
-- 0003 — Gamification (badges), trusted devices, and the
--        new-user provisioning trigger.
-- ============================================================

-- ------------------------------------------------------------
-- badge_definitions : extensible catalog (data-driven). Trilingual.
-- Public read-only reference data; only service_role writes.
-- ------------------------------------------------------------
create table public.badge_definitions (
  id            uuid primary key default gen_random_uuid(),
  key           text not null unique,                 -- 'streak_30_silver'
  tier          text not null check (tier in ('bronze','silver','gold','diamond','special')),
  category      text not null default 'streak'
                check (category in ('streak','consistency','milestone','recovery','engagement','worship')),
  title         jsonb not null,                        -- {ar,en,fr}
  description   jsonb not null default '{}'::jsonb,    -- {ar,en,fr}
  icon          text,
  criteria_type text not null check (criteria_type in
                ('streak_clean_days','total_clean_days','days_logged','week_completed',
                 'comeback_after_relapse','first_log','custom')),
  threshold     int,
  track         text check (track in ('break','build')),  -- null = any track
  sort_order    int not null default 0,
  is_active     boolean not null default true
);
alter table public.badge_definitions enable row level security;
create policy badge_defs_read on public.badge_definitions
  for select using (is_active);

-- ------------------------------------------------------------
-- earned_badges : which badges a user unlocked.
-- INSERT only via SECURITY DEFINER award routine / service_role
-- (clients cannot self-grant). Client may UPDATE only celebrated_at.
-- ------------------------------------------------------------
create table public.earned_badges (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references auth.users(id) on delete cascade,
  habit_id       uuid references public.habits(id) on delete cascade,
  badge_key      text not null references public.badge_definitions(key),
  earned_at      timestamptz not null default now(),
  celebrated_at  timestamptz,
  snapshot_streak int,
  unique (user_id, badge_key, habit_id)
);
alter table public.earned_badges enable row level security;

create policy earned_badges_select_self on public.earned_badges
  for select using (auth.uid() = user_id);
-- Client UPDATE allowed (to mark celebration shown) but locked to celebrated_at only:
create policy earned_badges_update_self on public.earned_badges
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
-- No client INSERT/DELETE policy => only service_role / award_badge() may insert.

-- Guard: on UPDATE by a non-service role, freeze every column except celebrated_at.
create or replace function public.earned_badges_lock_columns()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if current_setting('request.jwt.claim.role', true) is distinct from 'service_role' then
    new.id              := old.id;
    new.user_id         := old.user_id;
    new.habit_id        := old.habit_id;
    new.badge_key       := old.badge_key;
    new.earned_at       := old.earned_at;
    new.snapshot_streak := old.snapshot_streak;
  end if;
  return new;
end;
$$;
create trigger trg_earned_badges_lock
  before update on public.earned_badges
  for each row execute function public.earned_badges_lock_columns();

create index idx_earned_badges_user on public.earned_badges(user_id, habit_id);

-- ------------------------------------------------------------
-- award_badge(): SECURITY DEFINER helper used by the Edge Function
-- / SQL re-validation to grant a badge idempotently.
-- ------------------------------------------------------------
create or replace function public.award_badge(
  p_user_id uuid, p_habit_id uuid, p_badge_key text, p_streak int
) returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  insert into public.earned_badges (user_id, habit_id, badge_key, snapshot_streak)
  values (p_user_id, p_habit_id, p_badge_key, p_streak)
  on conflict (user_id, badge_key, habit_id) do nothing;
end;
$$;
revoke all on function public.award_badge(uuid,uuid,text,int) from public;
-- granted to service_role implicitly; not exposed to authenticated clients.

-- ------------------------------------------------------------
-- trusted_devices : core of "skip OTP on trusted devices".
-- Stores only a HASH of the device secret. INSERT is server-side
-- only (verify-otp Edge Function with service_role).
-- ------------------------------------------------------------
create table public.trusted_devices (
  id                uuid primary key default gen_random_uuid(),
  user_id           uuid not null references auth.users(id) on delete cascade,
  device_token_hash text not null,                  -- sha256(secret)
  device_label      text,
  platform          text,
  last_ip           inet,
  last_used_at      timestamptz,
  expires_at        timestamptz not null default (now() + interval '90 days'),
  revoked_at        timestamptz,
  created_at        timestamptz not null default now(),
  unique (user_id, device_token_hash)
);
alter table public.trusted_devices enable row level security;

create policy trusted_devices_select_self on public.trusted_devices
  for select using (auth.uid() = user_id);
create policy trusted_devices_update_self on public.trusted_devices   -- revoke
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy trusted_devices_delete_self on public.trusted_devices
  for delete using (auth.uid() = user_id);
-- No client INSERT policy => only the Edge Function (service_role) registers a device.
create index idx_trusted_devices_user on public.trusted_devices(user_id);

-- ------------------------------------------------------------
-- handle_new_user : provision profile + free subscription on signup.
-- Default custom fields + starter habit are seeded client-side from
-- the chosen onboarding template (works offline) and synced up.
-- ------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  insert into public.profiles (id, full_name, email, locale)
  values (
    new.id,
    coalesce(nullif(trim(new.raw_user_meta_data->>'full_name'), ''), 'مستخدم'),
    new.email,
    coalesce(nullif(new.raw_user_meta_data->>'locale',''), 'ar')
  )
  on conflict (id) do nothing;

  insert into public.subscriptions (user_id, tier)
  values (new.id, 'free')
  on conflict (user_id) do nothing;

  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

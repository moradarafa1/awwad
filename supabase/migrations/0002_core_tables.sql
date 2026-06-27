-- ============================================================
-- 0002 — Core user tables (profiles, catalog, habits, survey,
--        customization, entries) with Row-Level Security.
-- Convention: every user-owned row is isolated to auth.uid().
-- Child tables also verify parent ownership in WITH CHECK.
-- ============================================================

-- ------------------------------------------------------------
-- profiles : 1:1 with auth.users — the private per-user profile.
-- ------------------------------------------------------------
create table public.profiles (
  id                    uuid primary key references auth.users(id) on delete cascade,
  full_name             text not null check (char_length(trim(full_name)) >= 2),
  email                 text,                                   -- mirror for admin convenience only
  locale                text not null default 'ar' check (locale in ('ar','en','fr')),
  timezone              text not null default 'Africa/Cairo',
  show_religious_content boolean not null default true,
  reminder_hour         smallint default 20 check (reminder_hour between 0 and 23),
  notifications_enabled boolean not null default true,
  onboarding_done       boolean not null default false,
  last_active_at        timestamptz,
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now()
);
alter table public.profiles enable row level security;

create policy profiles_select_self on public.profiles
  for select using (auth.uid() = id);
create policy profiles_update_self on public.profiles
  for update using (auth.uid() = id) with check (auth.uid() = id);
create policy profiles_insert_self on public.profiles
  for insert with check (auth.uid() = id);
-- delete handled via auth.users cascade.

create trigger trg_profiles_updated
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- ------------------------------------------------------------
-- subscriptions : placeholder for future paid tier (design-for).
-- ------------------------------------------------------------
create table public.subscriptions (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null unique references auth.users(id) on delete cascade,
  tier        text not null default 'free' check (tier in ('free','monthly','yearly')),
  status      text not null default 'active',
  current_period_end timestamptz,
  provider    text,
  provider_ref text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
alter table public.subscriptions enable row level security;
create policy subscriptions_select_self on public.subscriptions
  for select using (auth.uid() = user_id);
-- No client write: only service_role / future billing webhook updates tier.
create trigger trg_subscriptions_updated
  before update on public.subscriptions
  for each row execute function public.set_updated_at();

-- ------------------------------------------------------------
-- habit_catalog : large reference list shown in onboarding.
-- Public read-only reference data (NOT user data). Trilingual.
-- ------------------------------------------------------------
create table public.habit_catalog (
  id                  uuid primary key default gen_random_uuid(),
  key                 text not null unique,                    -- stable slug e.g. 'quit_smoking'
  track               text not null check (track in ('break','build')),
  category            text not null,                           -- e.g. health, worship, productivity, mind, social
  title               jsonb not null,                          -- {ar,en,fr}
  description         jsonb not null default '{}'::jsonb,      -- {ar,en,fr}
  icon                text,                                    -- emoji or asset key
  default_template_key text default 'generic',                -- 'hrt_8week' | 'generic' | ...
  is_islamic          boolean not null default false,
  islamweb_ref        text,                                    -- source URL when a ruling is involved
  popularity          int not null default 0,
  sort_order          int not null default 0,
  is_active           boolean not null default true
);
alter table public.habit_catalog enable row level security;
create policy habit_catalog_read on public.habit_catalog
  for select using (is_active);   -- readable by all (incl. anon) — non-PII reference data.
create index idx_habit_catalog_track on public.habit_catalog(track, category, sort_order);

-- ------------------------------------------------------------
-- habits : a user's enrolled habit/track.
-- ------------------------------------------------------------
create table public.habits (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references auth.users(id) on delete cascade,
  track           text not null check (track in ('break','build')),
  catalog_id      uuid references public.habit_catalog(id),  -- null for fully custom
  is_custom       boolean not null default false,
  title           text not null,
  reason          text,                                       -- "why" / motivation
  template_key    text not null default 'generic',
  total_weeks     int not null default 8,
  current_week    int not null default 1,
  status          text not null default 'active' check (status in ('active','paused','completed','archived')),
  current_streak  int not null default 0,
  longest_streak  int not null default 0,
  last_entry_date date,
  reminder_hour   smallint check (reminder_hour between 0 and 23),
  config          jsonb not null default '{}'::jsonb,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  is_deleted      boolean not null default false
);
alter table public.habits enable row level security;
create policy habits_all_self on public.habits
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create index idx_habits_user on public.habits(user_id, status);
create trigger trg_habits_updated
  before update on public.habits
  for each row execute function public.set_updated_at();

-- ------------------------------------------------------------
-- onboarding_survey : OPTIONAL research data (consent-gated).
-- User owns the row; admin reads via SECURITY DEFINER RPC.
-- ------------------------------------------------------------
create table public.onboarding_survey (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null unique references auth.users(id) on delete cascade,
  consent         boolean not null default false,
  age_range       text,         -- '<18','18-24','25-34','35-44','45-54','55+'
  gender          text,         -- 'male','female','prefer_not'
  country         text,
  city            text,
  marital_status  text,
  education        text,
  referral_source text,         -- how they heard about us
  habit_duration  text,         -- how long they've had the habit
  prior_attempts  text,
  motivation      text,
  impact_level    smallint check (impact_level between 1 and 5),
  extra           jsonb not null default '{}'::jsonb,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);
alter table public.onboarding_survey enable row level security;
create policy survey_all_self on public.onboarding_survey
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create trigger trg_survey_updated
  before update on public.onboarding_survey
  for each row execute function public.set_updated_at();

-- ------------------------------------------------------------
-- custom_field_defs : user-customizable tracking field groups.
-- ------------------------------------------------------------
create table public.custom_field_defs (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users(id) on delete cascade,
  habit_id     uuid references public.habits(id) on delete cascade,  -- null = applies to all
  field_group  text not null check (field_group in
                ('place','feeling','activity','competing_response','environment_action','mood','custom')),
  label        text not null,
  input_type   text not null default 'single_select' check (input_type in
                ('single_select','multi_select','checklist','scale','time','text','emoji')),
  is_hidden    boolean not null default false,
  is_system    boolean not null default false,
  sort_order   int not null default 0,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  is_deleted   boolean not null default false
);
alter table public.custom_field_defs enable row level security;
create policy field_defs_all_self on public.custom_field_defs
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create index idx_field_defs on public.custom_field_defs(user_id, habit_id, field_group, sort_order);
create trigger trg_field_defs_updated
  before update on public.custom_field_defs
  for each row execute function public.set_updated_at();

-- ------------------------------------------------------------
-- custom_field_options : the selectable chips for a field def.
-- ------------------------------------------------------------
create table public.custom_field_options (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users(id) on delete cascade,
  field_def_id uuid not null references public.custom_field_defs(id) on delete cascade,
  label        text not null,
  emoji        text,
  option_key   text,                              -- stable slug for analytics
  is_hidden    boolean not null default false,
  sort_order   int not null default 0,
  created_at   timestamptz not null default now(),
  is_deleted   boolean not null default false
);
alter table public.custom_field_options enable row level security;
create policy field_options_all_self on public.custom_field_options
  for all
  using (auth.uid() = user_id)
  with check (
    auth.uid() = user_id
    and exists (select 1 from public.custom_field_defs d
                where d.id = field_def_id and d.user_id = auth.uid())
  );
create index idx_field_options on public.custom_field_options(field_def_id, sort_order);

-- ------------------------------------------------------------
-- daily_entries : one row per habit per day.
-- ------------------------------------------------------------
create table public.daily_entries (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users(id) on delete cascade,
  habit_id      uuid not null references public.habits(id) on delete cascade,
  entry_date    date not null,
  week_no       int,
  urge_level    int check (urge_level between 1 and 10),
  resistance_level int check (resistance_level between 1 and 10),
  did_slip      boolean,                          -- generalized "pulled?"
  adherence     text,                             -- medication / commitment status
  mood_label    text,
  mood_emoji    text,
  note          text,
  client_created_at timestamptz,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  is_deleted    boolean not null default false,
  unique (habit_id, entry_date)
);
alter table public.daily_entries enable row level security;
create policy daily_entries_all_self on public.daily_entries
  for all
  using (auth.uid() = user_id)
  with check (
    auth.uid() = user_id
    and exists (select 1 from public.habits h
                where h.id = habit_id and h.user_id = auth.uid())
  );
create index idx_entries_user_date on public.daily_entries(user_id, entry_date);
create index idx_entries_habit_date on public.daily_entries(habit_id, entry_date);
create trigger trg_entries_updated
  before update on public.daily_entries
  for each row execute function public.set_updated_at();

-- ------------------------------------------------------------
-- entry_events : multiple discrete events inside one day.
-- ------------------------------------------------------------
create table public.entry_events (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users(id) on delete cascade,
  entry_id      uuid not null references public.daily_entries(id) on delete cascade,
  occurred_at   time,
  event_type    text,                              -- 'automatic' | 'intentional'
  place_option_id    uuid references public.custom_field_options(id),
  activity_option_id uuid references public.custom_field_options(id),
  feeling_option_id  uuid references public.custom_field_options(id),
  -- denormalized label snapshots so history never breaks if a field is edited/hidden:
  place_label   text,
  activity_label text,
  feeling_label text,
  free_values   jsonb not null default '{}'::jsonb,
  created_at    timestamptz not null default now(),
  is_deleted    boolean not null default false
);
alter table public.entry_events enable row level security;
create policy entry_events_all_self on public.entry_events
  for all
  using (auth.uid() = user_id)
  with check (
    auth.uid() = user_id
    and exists (select 1 from public.daily_entries e
                where e.id = entry_id and e.user_id = auth.uid())
  );
create index idx_entry_events on public.entry_events(entry_id);

-- ------------------------------------------------------------
-- entry_selections : checklist / multi-select choices per day.
-- ------------------------------------------------------------
create table public.entry_selections (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users(id) on delete cascade,
  entry_id      uuid not null references public.daily_entries(id) on delete cascade,
  field_group   text not null,                     -- competing_response | environment_action
  field_def_id  uuid references public.custom_field_defs(id),
  option_id     uuid references public.custom_field_options(id),
  label_snapshot text,
  was_checked   boolean not null default true,
  created_at    timestamptz not null default now()
);
alter table public.entry_selections enable row level security;
create policy entry_selections_all_self on public.entry_selections
  for all
  using (auth.uid() = user_id)
  with check (
    auth.uid() = user_id
    and exists (select 1 from public.daily_entries e
                where e.id = entry_id and e.user_id = auth.uid())
  );
create index idx_entry_selections on public.entry_selections(entry_id);

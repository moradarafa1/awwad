-- ============================================================
-- 0006 — Registration profile fields.
-- Gender is collected (mandatory in the app UI) at sign-up; country,
-- birth_date and whatsapp are optional (research/development only, never sold).
-- Columns are nullable at the DB level; the app enforces gender as required.
-- ============================================================

alter table public.profiles
  add column if not exists gender     text check (gender in ('male','female')),
  add column if not exists country    text,
  add column if not exists birth_date date,
  add column if not exists whatsapp   text;

-- Re-provision the new fields from sign-up metadata.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  insert into public.profiles (id, full_name, email, locale, gender, country, birth_date, whatsapp)
  values (
    new.id,
    coalesce(nullif(trim(new.raw_user_meta_data->>'full_name'), ''), 'مستخدم'),
    new.email,
    coalesce(nullif(new.raw_user_meta_data->>'locale',''), 'ar'),
    nullif(new.raw_user_meta_data->>'gender',''),
    nullif(new.raw_user_meta_data->>'country',''),
    (nullif(new.raw_user_meta_data->>'birth_date','')::date),
    nullif(new.raw_user_meta_data->>'whatsapp','')
  )
  on conflict (id) do nothing;

  insert into public.subscriptions (user_id, tier)
  values (new.id, 'free')
  on conflict (user_id) do nothing;

  return new;
end;
$$;

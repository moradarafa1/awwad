-- ============================================================
-- 0001 — Extensions & shared helpers
-- عوّاد (Awwad) — Supabase backend
-- ============================================================

create extension if not exists pgcrypto;      -- gen_random_uuid()

-- ------------------------------------------------------------
-- updated_at auto-touch trigger function
-- ------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ------------------------------------------------------------
-- is_admin(): single source of truth for admin gating.
-- SECURITY DEFINER with a pinned search_path (privilege-escalation safe).
-- ------------------------------------------------------------
create table if not exists public.admin_users (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  role       text not null default 'owner',
  created_at timestamptz not null default now()
);
alter table public.admin_users enable row level security;

-- An admin may confirm their own row; nobody can enumerate the list.
create policy admin_users_select_self
  on public.admin_users for select
  using (auth.uid() = user_id);
-- No insert/update/delete policy => only service_role can write.

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (select 1 from public.admin_users a where a.user_id = auth.uid());
$$;

revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to authenticated;

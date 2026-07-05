-- 0007: ops heartbeat - a real DB WRITE for the keep-alive pingers.
-- Supabase's free-tier inactivity scanner flagged the project even though a
-- REST SELECT ran every 3 days (2026-07-04 email: "not sufficient activity").
-- A genuine write via RPC is a much stronger activity signal.
--
-- Security model: the table itself is locked down (RLS on, no policies, no
-- grants). The ONLY write path is the SECURITY DEFINER heartbeat() function,
-- which can merely bump the single-row timestamp - safe to expose to anon.

create table if not exists public.ops_heartbeat (
  id int primary key check (id = 1),
  pinged_at timestamptz not null default now(),
  source text not null default 'unknown'
);

alter table public.ops_heartbeat enable row level security;
revoke all on table public.ops_heartbeat from anon, authenticated;

insert into public.ops_heartbeat (id, source) values (1, 'migration')
on conflict (id) do nothing;

create or replace function public.heartbeat(src text default 'ping')
returns timestamptz
language sql
security definer
set search_path = public
as $$
  insert into public.ops_heartbeat as h (id, pinged_at, source)
  values (1, now(), left(coalesce(src, 'ping'), 40))
  on conflict (id) do update
    set pinged_at = now(), source = left(coalesce(src, 'ping'), 40)
  returning pinged_at;
$$;

-- anon may call ONLY this function (worst case: someone bumps a timestamp).
grant execute on function public.heartbeat(text) to anon, authenticated;

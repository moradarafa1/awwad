-- ============================================================
-- 0009: allow 0 (and NULL) ratings so excused-day (skip) entries can sync.
-- Skip entries carry no urge/resistance rating; the client now sends NULL
-- for them, and 0 is additionally tolerated for defense in depth (older
-- clients in the wild still send 0). Applied live 2026-07-17.
-- ============================================================

alter table public.daily_entries
  drop constraint if exists daily_entries_urge_level_check;
alter table public.daily_entries
  add constraint daily_entries_urge_level_check
  check (urge_level is null or urge_level between 0 and 10);

alter table public.daily_entries
  drop constraint if exists daily_entries_resistance_level_check;
alter table public.daily_entries
  add constraint daily_entries_resistance_level_check
  check (resistance_level is null or resistance_level between 0 and 10);

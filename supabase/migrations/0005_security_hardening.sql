-- ============================================================
-- 0005 — Security hardening: lock down function EXECUTE grants.
-- Supabase default privileges auto-GRANT EXECUTE on every new
-- function to anon + authenticated (+ service_role). That direct
-- grant SURVIVES `revoke ... from public`, so the earlier migrations'
-- revokes were ineffective against anon. This migration revokes the
-- real anon/authenticated grants where a function must not be a
-- public RPC. (Found via supabase get_advisors after deploy.)
-- ============================================================

-- 1) Pin search_path on the updated_at trigger fn (linter 0011).
alter function public.set_updated_at() set search_path = public, pg_temp;

-- 2) Trigger-only & service-only functions: NO client may call these.
--    Triggers still fire — trigger execution does not check the
--    invoking role's EXECUTE privilege on the trigger function.
revoke all on function public.set_updated_at()                from public, anon, authenticated;
revoke all on function public.handle_new_user()               from public, anon, authenticated;
revoke all on function public.earned_badges_lock_columns()    from public, anon, authenticated;

-- award_badge: must be service_role-only (badges are granted server-side,
-- never self-granted by a client). This is the security-critical fix.
revoke all on function public.award_badge(uuid,uuid,text,int) from public, anon, authenticated;
grant execute on function public.award_badge(uuid,uuid,text,int) to service_role;

-- 3) Admin / identity functions: a SIGNED-IN app may call them (each is
--    self-gated internally by is_admin(): plpgsql ones raise 'forbidden',
--    sql ones filter on `where is_admin()` so non-admins get empty sets).
--    Anonymous visitors must not call them at all → revoke anon.
revoke all on function public.is_admin()                       from anon;
revoke all on function public.admin_overview()                 from anon;
revoke all on function public.admin_daily_active(int)          from anon;
revoke all on function public.admin_track_split()              from anon;
revoke all on function public.admin_top_habits(int)            from anon;
revoke all on function public.admin_badge_distribution()       from anon;
revoke all on function public.admin_survey_aggregate()         from anon;
revoke all on function public.admin_survey_individual(int,int) from anon;

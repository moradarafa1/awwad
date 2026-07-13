-- 0008: streak protection + relapse journal.
-- entry_type: 'log' (normal) | 'skip' (excused day: travel/sickness -
-- transparent to streaks). trigger_key: what preceded a slip (relapse
-- journal analysis), e.g. 'stress' | 'boredom' | 'loneliness' | ...
alter table public.daily_entries
  add column if not exists entry_type text not null default 'log'
    check (entry_type in ('log', 'skip')),
  add column if not exists trigger_key text;

comment on column public.daily_entries.entry_type is
  'log = normal daily log; skip = excused day, transparent to streaks';
comment on column public.daily_entries.trigger_key is
  'relapse-journal trigger behind a slip (stress/boredom/...)';

alter table public.works
  add column if not exists sacem_reminder_date date;

create index if not exists works_sacem_reminder_idx
  on public.works(artist_id, sacem_reminder_date)
  where sacem_status = 'to_do' and sacem_reminder_date is not null;

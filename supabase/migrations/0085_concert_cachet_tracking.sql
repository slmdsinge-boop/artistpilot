-- Track whether an artist engagement is declared as a cachet without double-counting it with entered hours.
alter table public.concerts
  add column if not exists cachet_count integer;

alter table public.concerts
  add constraint concerts_cachet_count_domain
  check (cachet_count is null or cachet_count between 0 and 28);

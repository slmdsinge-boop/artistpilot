-- Mirror Server Action validation for project count fields at the database boundary.
-- Counts represent discrete, non-negative quantities; direct API writes must not
-- bypass the integer/non-negative validation already enforced by the application.

do $$
begin
  if exists (
    select 1
    from public.projects
    where (performance_count is not null and (performance_count < 0 or performance_count <> trunc(performance_count)))
       or (artist_count is not null and (artist_count < 0 or artist_count <> trunc(artist_count)))
  ) then
    raise exception 'project count domain preflight failed: review negative or fractional count values';
  end if;
end $$;

alter table public.projects
  drop constraint if exists projects_performance_count_nonnegative_integer;
alter table public.projects
  add constraint projects_performance_count_nonnegative_integer
  check (
    performance_count is null
    or (performance_count >= 0 and performance_count = trunc(performance_count))
  );

alter table public.projects
  drop constraint if exists projects_artist_count_nonnegative_integer;
alter table public.projects
  add constraint projects_artist_count_nonnegative_integer
  check (
    artist_count is null
    or (artist_count >= 0 and artist_count = trunc(artist_count))
  );

comment on constraint projects_performance_count_nonnegative_integer on public.projects is
'Performance count is unknown/null or a non-negative whole number, matching Server Action validation.';

comment on constraint projects_artist_count_nonnegative_integer on public.projects is
'Artist count is unknown/null or a non-negative whole number, matching Server Action validation.';

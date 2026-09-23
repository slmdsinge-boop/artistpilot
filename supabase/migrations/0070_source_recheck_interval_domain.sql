-- Source freshness windows must be positive.
-- A zero or negative recheck interval would make a verified source immediately stale
-- (or semantically inverted) and could be written through a direct API/admin path.

do $$
begin
  if exists (
    select 1 from public.funding_programs
    where recheck_after <= interval '0 seconds'
  )
  or exists (
    select 1 from public.funding_criteria
    where recheck_after <= interval '0 seconds'
  ) then
    raise exception 'source recheck interval preflight failed: review non-positive freshness windows';
  end if;
end $$;

alter table public.funding_programs
  drop constraint if exists funding_programs_recheck_after_positive;
alter table public.funding_programs
  add constraint funding_programs_recheck_after_positive
  check (recheck_after > interval '0 seconds');

alter table public.funding_criteria
  drop constraint if exists funding_criteria_recheck_after_positive;
alter table public.funding_criteria
  add constraint funding_criteria_recheck_after_positive
  check (recheck_after > interval '0 seconds');

comment on constraint funding_programs_recheck_after_positive on public.funding_programs is
'Program source re-verification window must be strictly positive.';

comment on constraint funding_criteria_recheck_after_positive on public.funding_criteria is
'Criterion source re-verification window must be strictly positive.';

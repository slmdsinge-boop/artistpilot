-- Mirror Server Action business-date rules at the database trust boundary.
-- Historical milestone/completion dates may be today or earlier, never future.
-- due_date is intentionally excluded because obligations may legitimately be due later.

do $$
declare
  paris_today date := (now() at time zone 'Europe/Paris')::date;
begin
  if exists (
    select 1
    from public.funding_applications
    where submitted_at > paris_today
       or decision_at > paris_today
  )
  or exists (
    select 1
    from public.funding_obligations
    where completed_at > paris_today
  ) then
    raise exception 'funding business-date preflight failed: review future historical dates before migration 0058';
  end if;
end $$;

create or replace function public.guard_funding_application_business_dates()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
declare
  paris_today date := (now() at time zone 'Europe/Paris')::date;
begin
  if new.submitted_at is not null and new.submitted_at > paris_today then
    raise exception 'Funding application submission date cannot be in the future';
  end if;
  if new.decision_at is not null and new.decision_at > paris_today then
    raise exception 'Funding application decision date cannot be in the future';
  end if;
  return new;
end;
$$;

drop trigger if exists funding_applications_business_dates on public.funding_applications;
create trigger funding_applications_business_dates
before insert or update of submitted_at, decision_at
on public.funding_applications
for each row execute function public.guard_funding_application_business_dates();

create or replace function public.guard_funding_obligation_completion_date()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
declare
  paris_today date := (now() at time zone 'Europe/Paris')::date;
begin
  if new.completed_at is not null and new.completed_at > paris_today then
    raise exception 'Funding obligation completion date cannot be in the future';
  end if;
  return new;
end;
$$;

drop trigger if exists funding_obligations_completion_date on public.funding_obligations;
create trigger funding_obligations_completion_date
before insert or update of completed_at
on public.funding_obligations
for each row execute function public.guard_funding_obligation_completion_date();

comment on function public.guard_funding_application_business_dates() is
'Prevents future submission and decision dates using the Europe/Paris business date, matching application Server Actions.';

comment on function public.guard_funding_obligation_completion_date() is
'Prevents future obligation completion dates using the Europe/Paris business date; due dates remain unrestricted.';

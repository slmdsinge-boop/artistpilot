-- Validate conditional criterion metadata at the database boundary.
-- V2.3 currently supports only equality conditions in applies_when. Malformed or
-- unsupported metadata must not silently become executable verified eligibility logic.

do $$
begin
  if exists (
    select 1
    from public.funding_criteria fc
    where fc.applies_when is not null
      and (
        jsonb_typeof(fc.applies_when) <> 'object'
        or nullif(fc.applies_when->>'fact_key','') is null
        or (fc.applies_when->>'subject_type') not in ('artist','organization','project','application')
        or coalesce(fc.applies_when->>'operator','eq') <> 'eq'
        or not (fc.applies_when ? 'value')
        or not exists (
          select 1
          from public.fact_definitions fd
          where fd.fact_key = fc.applies_when->>'fact_key'
            and fd.subject_type = fc.applies_when->>'subject_type'
        )
      )
  ) then
    raise exception 'conditional criteria preflight failed: review malformed or unsupported applies_when metadata before migration 0062';
  end if;
end $$;

create or replace function public.guard_funding_criterion_applies_when()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  if new.applies_when is null then
    return new;
  end if;

  if jsonb_typeof(new.applies_when) <> 'object'
     or nullif(new.applies_when->>'fact_key','') is null
     or (new.applies_when->>'subject_type') not in ('artist','organization','project','application')
     or coalesce(new.applies_when->>'operator','eq') <> 'eq'
     or not (new.applies_when ? 'value') then
    raise exception 'Invalid or unsupported funding criterion applies_when metadata';
  end if;

  if not exists (
    select 1
    from public.fact_definitions fd
    where fd.fact_key = new.applies_when->>'fact_key'
      and fd.subject_type = new.applies_when->>'subject_type'
  ) then
    raise exception 'Conditional funding criterion references an undefined fact';
  end if;

  return new;
end;
$$;

drop trigger if exists funding_criteria_guard_applies_when on public.funding_criteria;
create trigger funding_criteria_guard_applies_when
before insert or update of applies_when
on public.funding_criteria
for each row execute function public.guard_funding_criterion_applies_when();

comment on function public.guard_funding_criterion_applies_when() is
'Requires applies_when to reference a canonical fact definition and use the equality condition currently supported by eligibility V2.3.';

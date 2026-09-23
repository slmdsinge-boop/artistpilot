-- Conditional metadata must use a value compatible with the referenced fact definition.
-- Reuse the same canonical JSON type semantics as entity_facts.

create or replace function public.funding_condition_value_is_valid(condition jsonb)
returns boolean
language sql
stable
security invoker
set search_path = public
as $$
  select coalesce((
    select case
      when fd.value_type = 'boolean' then jsonb_typeof(condition->'value') = 'boolean'
      when fd.value_type = 'number' then jsonb_typeof(condition->'value') = 'number'
      when fd.value_type = 'text' then jsonb_typeof(condition->'value') = 'string'
      when fd.value_type = 'enum' then
        jsonb_typeof(condition->'value') = 'string'
        and jsonb_typeof(fd.options) = 'array'
        and fd.options @> jsonb_build_array(condition->'value')
      when fd.value_type = 'date' then
        jsonb_typeof(condition->'value') = 'string'
        and (condition->>'value') ~ '^\d{4}-\d{2}-\d{2}$'
        and to_char(to_date(condition->>'value','YYYY-MM-DD'),'YYYY-MM-DD') = condition->>'value'
      else false
    end
    from public.fact_definitions fd
    where fd.fact_key = condition->>'fact_key'
      and fd.subject_type = condition->>'subject_type'
  ), false);
$$;

do $$
begin
  if exists (
    select 1
    from public.funding_criteria fc
    where fc.applies_when is not null
      and not public.funding_condition_value_is_valid(fc.applies_when)
  ) then
    raise exception 'conditional criteria value-type preflight failed: review applies_when values before migration 0063';
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

  if not public.funding_condition_value_is_valid(new.applies_when) then
    raise exception 'Conditional funding criterion value does not match its fact definition';
  end if;

  return new;
end;
$$;

comment on function public.funding_condition_value_is_valid(jsonb) is
'Checks applies_when value type, enum membership and ISO date validity against the referenced canonical fact definition.';

comment on function public.guard_funding_criterion_applies_when() is
'Requires supported conditional metadata, a canonical fact definition, and a condition value compatible with that definition.';

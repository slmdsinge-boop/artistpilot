-- Enforce fact-definition value types at the database trust boundary.
-- The UI/server already validates these answers; this prevents authenticated
-- direct API writes from storing JSON values that contradict fact_definitions.

do $$
begin
  if exists (
    select 1
    from public.entity_facts ef
    join public.fact_definitions fd
      on fd.fact_key = ef.fact_key
     and fd.subject_type = ef.subject_type
    where (fd.value_type = 'boolean' and jsonb_typeof(ef.value) <> 'boolean')
       or (fd.value_type = 'number' and jsonb_typeof(ef.value) <> 'number')
       or (fd.value_type in ('text','date','enum') and jsonb_typeof(ef.value) <> 'string')
       or (
         fd.value_type = 'enum'
         and (
           jsonb_typeof(fd.options) <> 'array'
           or not (fd.options @> jsonb_build_array(ef.value))
         )
       )
       or (
         fd.value_type = 'date'
         and not ((ef.value #>> '{}') ~ '^\\d{4}-\\d{2}-\\d{2}$')
       )
  ) then
    raise exception 'Existing eligibility facts violate fact-definition value types';
  end if;
end $$;

create or replace function public.guard_entity_fact_value_type()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
declare
  definition public.fact_definitions%rowtype;
  raw_text text;
begin
  select * into definition
  from public.fact_definitions fd
  where fd.fact_key = new.fact_key
    and fd.subject_type = new.subject_type;

  if definition.fact_key is null then
    raise exception 'entity fact definition missing or subject_type mismatch';
  end if;

  if definition.value_type = 'boolean' and jsonb_typeof(new.value) <> 'boolean' then
    raise exception 'entity fact value must be boolean';
  elsif definition.value_type = 'number' and jsonb_typeof(new.value) <> 'number' then
    raise exception 'entity fact value must be number';
  elsif definition.value_type in ('text','date','enum') and jsonb_typeof(new.value) <> 'string' then
    raise exception 'entity fact value must be string';
  end if;

  if definition.value_type = 'enum' then
    if jsonb_typeof(definition.options) <> 'array'
       or not (definition.options @> jsonb_build_array(new.value)) then
      raise exception 'entity fact enum value is not an allowed option';
    end if;
  end if;

  if definition.value_type = 'date' then
    raw_text := new.value #>> '{}';
    if raw_text !~ '^\\d{4}-\\d{2}-\\d{2}$'
       or to_char(to_date(raw_text, 'YYYY-MM-DD'), 'YYYY-MM-DD') <> raw_text then
      raise exception 'entity fact date must be a valid ISO calendar date';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists entity_facts_value_type on public.entity_facts;
create trigger entity_facts_value_type
before insert or update of fact_key, subject_type, value
on public.entity_facts
for each row execute function public.guard_entity_fact_value_type();

comment on function public.guard_entity_fact_value_type() is
'Enforces canonical JSON value types, enum options and valid ISO dates from fact_definitions for eligibility facts.';

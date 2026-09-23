-- fact_definitions are executable schema metadata. Existing guards validate facts and
-- criteria when those dependent rows are written, but changing/deleting the definition
-- itself could otherwise invalidate already stored evidence or executable criteria.

create or replace function public.guard_fact_definition_lifecycle()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  if tg_op = 'DELETE' then
    if exists (
      select 1 from public.entity_facts ef
      where ef.fact_key = old.fact_key and ef.subject_type = old.subject_type
    ) or exists (
      select 1 from public.funding_criteria fc
      where (fc.criterion_key = old.fact_key and fc.subject_type = old.subject_type)
         or (
           fc.applies_when is not null
           and fc.applies_when->>'fact_key' = old.fact_key
           and fc.applies_when->>'subject_type' = old.subject_type
         )
    ) then
      raise exception 'fact definition is referenced and cannot be deleted';
    end if;
    return old;
  end if;

  if new.fact_key <> old.fact_key
     or new.subject_type <> old.subject_type
     or new.value_type <> old.value_type
     or new.options is distinct from old.options then
    if exists (
      select 1 from public.entity_facts ef
      where ef.fact_key = old.fact_key and ef.subject_type = old.subject_type
    ) or exists (
      select 1 from public.funding_criteria fc
      where (fc.criterion_key = old.fact_key and fc.subject_type = old.subject_type)
         or (
           fc.applies_when is not null
           and fc.applies_when->>'fact_key' = old.fact_key
           and fc.applies_when->>'subject_type' = old.subject_type
         )
    ) then
      raise exception 'referenced fact definition identity or type metadata cannot be changed in place';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists fact_definitions_lifecycle_guard on public.fact_definitions;
create trigger fact_definitions_lifecycle_guard
before update or delete on public.fact_definitions
for each row execute function public.guard_fact_definition_lifecycle();

comment on function public.guard_fact_definition_lifecycle() is
'Protects referenced fact-definition identity/type metadata and prevents deletion while entity facts or funding criteria depend on it.';

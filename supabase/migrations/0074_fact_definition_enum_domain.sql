-- Enum fact definitions are executable validation metadata, not free-form documentation.
-- Require a non-empty array of unique string options so direct/admin writes cannot
-- create an enum that the questionnaire and entity-fact guard cannot safely use.

do $$
begin
  if exists (
    select 1
    from public.fact_definitions fd
    where fd.value_type = 'enum'
      and (
        jsonb_typeof(fd.options) <> 'array'
        or jsonb_array_length(fd.options) = 0
        or exists (
          select 1
          from jsonb_array_elements(fd.options) option_value
          where jsonb_typeof(option_value) <> 'string'
        )
        or (
          select count(*)
          from jsonb_array_elements(fd.options)
        ) <> (
          select count(distinct option_value)
          from jsonb_array_elements(fd.options) option_value
        )
      )
  ) then
    raise exception 'fact definition enum preflight failed: review invalid enum options';
  end if;
end $$;

create or replace function public.guard_fact_definition_options()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  if new.value_type = 'enum' then
    if jsonb_typeof(new.options) <> 'array'
       or jsonb_array_length(new.options) = 0
       or exists (
         select 1
         from jsonb_array_elements(new.options) option_value
         where jsonb_typeof(option_value) <> 'string'
       )
       or (
         select count(*)
         from jsonb_array_elements(new.options)
       ) <> (
         select count(distinct option_value)
         from jsonb_array_elements(new.options) option_value
       ) then
      raise exception 'enum fact definition requires non-empty unique string options';
    end if;
  elsif new.options is not null then
    raise exception 'non-enum fact definition cannot define enum options';
  end if;

  return new;
end;
$$;

drop trigger if exists fact_definitions_options_guard on public.fact_definitions;
create trigger fact_definitions_options_guard
before insert or update of value_type, options
on public.fact_definitions
for each row execute function public.guard_fact_definition_options();

comment on function public.guard_fact_definition_options() is
'Keeps enum fact metadata executable: enum options are non-empty unique strings; non-enum definitions do not carry enum options.';

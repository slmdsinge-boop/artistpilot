-- Executable eligibility criteria must compare values using metadata compatible with
-- their canonical fact definition. Otherwise a verified admin/direct write can turn a
-- type mismatch into a false deterministic "criterion_not_met".

create or replace function public.funding_criterion_expected_value_is_valid(
  criterion_subject_type text,
  criterion_key text,
  criterion_operator text,
  criterion_expected_value jsonb
)
returns boolean
language sql
stable
security invoker
set search_path = public
as $$
  select coalesce((
    select case
      when criterion_operator = 'not_null' then criterion_expected_value is null
      when criterion_operator in ('gte','lte','gt','lt') then
        fd.value_type = 'number'
        and jsonb_typeof(criterion_expected_value) = 'number'
      when criterion_operator = 'in' then
        jsonb_typeof(criterion_expected_value) = 'array'
        and jsonb_array_length(criterion_expected_value) > 0
        and not exists (
          select 1
          from jsonb_array_elements(criterion_expected_value) candidate
          where case fd.value_type
            when 'boolean' then jsonb_typeof(candidate) <> 'boolean'
            when 'number' then jsonb_typeof(candidate) <> 'number'
            when 'text' then jsonb_typeof(candidate) <> 'string'
            when 'enum' then
              jsonb_typeof(candidate) <> 'string'
              or jsonb_typeof(fd.options) <> 'array'
              or not (fd.options @> jsonb_build_array(candidate))
            when 'date' then
              jsonb_typeof(candidate) <> 'string'
              or not ((candidate #>> '{}') ~ '^\\d{4}-\\d{2}-\\d{2}$')
              or to_char(to_date(candidate #>> '{}','YYYY-MM-DD'),'YYYY-MM-DD') <> candidate #>> '{}'
            else true
          end
        )
      when criterion_operator in ('eq','neq') then
        case fd.value_type
          when 'boolean' then jsonb_typeof(criterion_expected_value) = 'boolean'
          when 'number' then jsonb_typeof(criterion_expected_value) = 'number'
          when 'text' then jsonb_typeof(criterion_expected_value) = 'string'
          when 'enum' then
            jsonb_typeof(criterion_expected_value) = 'string'
            and jsonb_typeof(fd.options) = 'array'
            and fd.options @> jsonb_build_array(criterion_expected_value)
          when 'date' then
            jsonb_typeof(criterion_expected_value) = 'string'
            and (criterion_expected_value #>> '{}') ~ '^\\d{4}-\\d{2}-\\d{2}$'
            and to_char(to_date(criterion_expected_value #>> '{}','YYYY-MM-DD'),'YYYY-MM-DD') = criterion_expected_value #>> '{}'
          else false
        end
      else false
    end
    from public.fact_definitions fd
    where fd.fact_key = criterion_key
      and fd.subject_type = criterion_subject_type
  ), false);
$$;

do $$
begin
  if exists (
    select 1
    from public.funding_criteria fc
    where fc.verification_status = 'verified'
      and fc.criterion_kind = 'eligibility'
      and not public.funding_criterion_expected_value_is_valid(
        fc.subject_type, fc.criterion_key, fc.operator, fc.expected_value
      )
  ) then
    raise exception 'criterion expected-value preflight failed: review verified eligibility metadata';
  end if;
end $$;

create or replace function public.guard_funding_criterion_expected_value()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  if new.verification_status = 'verified'
     and new.criterion_kind = 'eligibility'
     and not public.funding_criterion_expected_value_is_valid(
       new.subject_type, new.criterion_key, new.operator, new.expected_value
     ) then
    raise exception 'verified eligibility criterion expected value does not match its canonical fact definition';
  end if;
  return new;
end;
$$;

drop trigger if exists funding_criteria_expected_value_guard on public.funding_criteria;
create trigger funding_criteria_expected_value_guard
before insert or update of subject_type, criterion_key, operator, expected_value, verification_status, criterion_kind
on public.funding_criteria
for each row execute function public.guard_funding_criterion_expected_value();

comment on function public.funding_criterion_expected_value_is_valid(text,text,text,jsonb) is
'Validates executable eligibility comparison metadata against the canonical fact type, enum options and supported operator semantics.';

comment on function public.guard_funding_criterion_expected_value() is
'Prevents verified eligibility criteria from becoming executable with incompatible expected-value metadata.';

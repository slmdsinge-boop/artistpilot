-- Keep executable criterion operator/value pairs internally coherent.
-- not_null is the only operator that does not consume expected_value; every
-- comparison/membership operator needs an explicit expected value.

do $$
begin
  if exists (
    select 1
    from public.funding_criteria
    where verification_status = 'verified'
      and (
        (operator = 'not_null' and expected_value is not null)
        or (operator <> 'not_null' and expected_value is null)
        or (operator = 'in' and jsonb_typeof(expected_value) <> 'array')
      )
  ) then
    raise exception 'funding criterion operator/value preflight failed: review verified criterion metadata';
  end if;
end $$;

create or replace function public.guard_funding_criterion_operator_value()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  -- Draft/to-verify rows may remain incomplete while being researched.
  if new.verification_status <> 'verified' then
    return new;
  end if;

  if new.operator = 'not_null' then
    if new.expected_value is not null then
      raise exception 'verified not_null criterion must not define expected_value';
    end if;
  elsif new.expected_value is null then
    raise exception 'verified comparison criterion requires expected_value';
  end if;

  if new.operator = 'in' and jsonb_typeof(new.expected_value) <> 'array' then
    raise exception 'verified in criterion expected_value must be an array';
  end if;

  return new;
end;
$$;

drop trigger if exists funding_criteria_guard_operator_value on public.funding_criteria;
create trigger funding_criteria_guard_operator_value
before insert or update of operator, expected_value, verification_status
on public.funding_criteria
for each row execute function public.guard_funding_criterion_operator_value();

comment on function public.guard_funding_criterion_operator_value() is
'Verified criteria require coherent operator/expected_value metadata; draft criteria may remain incomplete during research.';

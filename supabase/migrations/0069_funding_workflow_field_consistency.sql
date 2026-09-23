-- Prevent direct API writes from attaching decision/award fields to workflow
-- states where those fields have no business meaning.
-- Historical fields remain valid for submitted/awarded/rejected/withdrawn as applicable.

do $$
begin
  if exists (
    select 1
    from public.funding_applications
    where (status in ('identified','to_check','eligible','preparing') and submitted_at is not null)
       or (status in ('identified','to_check','eligible','preparing','submitted') and decision_at is not null)
       or (status <> 'awarded' and awarded_amount_eur is not null)
  ) then
    raise exception 'funding workflow field consistency preflight failed: review milestone fields outside their workflow states';
  end if;
end $$;

alter table public.funding_applications
  drop constraint if exists funding_applications_workflow_fields_consistent;

alter table public.funding_applications
  add constraint funding_applications_workflow_fields_consistent
  check (
    (status not in ('identified','to_check','eligible','preparing') or submitted_at is null)
    and (status not in ('identified','to_check','eligible','preparing','submitted') or decision_at is null)
    and (status = 'awarded' or awarded_amount_eur is null)
  );

comment on constraint funding_applications_workflow_fields_consistent
on public.funding_applications is
'Prevents milestone and award fields from being populated before the corresponding funding workflow state.';

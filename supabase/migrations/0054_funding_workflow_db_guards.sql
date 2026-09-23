-- Enforce funding workflow invariants at the database trust boundary.
-- Mirrors rules already enforced by Server Actions so authenticated direct API
-- writes cannot create impossible application/obligation states.

do $$
begin
  if exists (
    select 1 from public.funding_obligations fo
    join public.funding_applications fa on fa.id = fo.funding_application_id
    where fa.artist_id <> fo.artist_id
       or fa.status <> 'awarded'
  )
  or exists (
    select 1 from public.funding_applications
    where (status in ('submitted','awarded','rejected') and submitted_at is null)
       or (status in ('awarded','rejected') and decision_at is null)
       or (status = 'awarded' and awarded_amount_eur is null)
  )
  or exists (
    select 1
    from public.funding_applications fa
    where fa.status <> 'awarded'
      and exists (
        select 1 from public.funding_obligations fo
        where fo.funding_application_id = fa.id
          and fo.status in ('to_do','in_progress')
      )
  ) then
    raise exception 'Existing funding workflow data violates application/obligation invariants';
  end if;
end $$;

alter table public.funding_applications
drop constraint if exists funding_applications_status_milestones_consistent;
alter table public.funding_applications
add constraint funding_applications_status_milestones_consistent
check (
  (status not in ('submitted','awarded','rejected') or submitted_at is not null)
  and (status not in ('awarded','rejected') or decision_at is not null)
  and (status <> 'awarded' or awarded_amount_eur is not null)
);

create or replace function public.guard_funding_obligation_award_scope()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  if not exists (
    select 1
    from public.funding_applications fa
    where fa.id = new.funding_application_id
      and fa.artist_id = new.artist_id
      and fa.status = 'awarded'
  ) then
    raise exception 'Funding obligations require an awarded application owned by the same artist';
  end if;
  return new;
end;
$$;

drop trigger if exists funding_obligations_require_award on public.funding_obligations;
create trigger funding_obligations_require_award
before insert or update of funding_application_id, artist_id
on public.funding_obligations
for each row execute function public.guard_funding_obligation_award_scope();

create or replace function public.guard_funding_application_award_exit()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  if old.status = 'awarded'
     and new.status <> 'awarded'
     and exists (
       select 1
       from public.funding_obligations fo
       where fo.funding_application_id = old.id
         and fo.artist_id = old.artist_id
         and fo.status in ('to_do','in_progress')
     ) then
    raise exception 'Active funding obligations must be resolved before leaving awarded status';
  end if;
  return new;
end;
$$;

drop trigger if exists funding_applications_guard_award_exit on public.funding_applications;
create trigger funding_applications_guard_award_exit
before update of status on public.funding_applications
for each row execute function public.guard_funding_application_award_exit();

comment on constraint funding_applications_status_milestones_consistent on public.funding_applications is
'Workflow milestones required by status: submission date for submitted/awarded/rejected, decision date for awarded/rejected, and awarded amount for awarded.';

comment on function public.guard_funding_obligation_award_scope() is
'Obligations may only belong to an awarded funding application owned by the same artist.';

comment on function public.guard_funding_application_award_exit() is
'Prevents leaving awarded status while active post-award obligations remain.';

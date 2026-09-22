-- Enforce project domain invariants at the database trust boundary.
-- Server Actions already validate these values; these checks prevent direct API
-- writes from bypassing the same business rules.

do $$
begin
  if exists (
    select 1 from public.projects
    where project_type not in ('album','ep','single','clip','tournee','spectacle','festival','residence','autre')
       or status not in ('idea','preparation','active','completed','paused')
       or (start_date is not null and target_date is not null and target_date < start_date)
       or (budget_eur is not null and budget_eur < 0)
  ) then
    raise exception 'Existing project data violates canonical project domain constraints';
  end if;
end $$;

alter table public.projects drop constraint if exists projects_project_type_canonical;
alter table public.projects add constraint projects_project_type_canonical
check (project_type in ('album','ep','single','clip','tournee','spectacle','festival','residence','autre'));

alter table public.projects drop constraint if exists projects_status_canonical;
alter table public.projects add constraint projects_status_canonical
check (status in ('idea','preparation','active','completed','paused'));

alter table public.projects drop constraint if exists projects_date_range_valid;
alter table public.projects add constraint projects_date_range_valid
check (start_date is null or target_date is null or target_date >= start_date);

alter table public.projects drop constraint if exists projects_budget_nonnegative;
alter table public.projects add constraint projects_budget_nonnegative
check (budget_eur is null or budget_eur >= 0);

comment on constraint projects_project_type_canonical on public.projects is
'Database mirror of the canonical ArtistPilot project-type vocabulary.';

comment on constraint projects_status_canonical on public.projects is
'Database mirror of the canonical ArtistPilot project workflow statuses.';

comment on constraint projects_date_range_valid on public.projects is
'Target date cannot precede project start date when both are known.';

comment on constraint projects_budget_nonnegative on public.projects is
'Project budget may be unknown but cannot be negative.';

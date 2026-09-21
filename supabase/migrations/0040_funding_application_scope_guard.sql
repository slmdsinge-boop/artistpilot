-- Keep funding application references inside the owning artist scope.
-- Foreign keys alone cannot guarantee that project/organization belong to the same artist.

create or replace function public.validate_funding_application_scope()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.project_id is not null and not exists (
    select 1 from public.projects p
    where p.id = new.project_id and p.artist_id = new.artist_id
  ) then
    raise exception 'Funding application project must belong to the same artist';
  end if;

  if new.organization_id is not null and not exists (
    select 1 from public.organizations o
    where o.id = new.organization_id and o.artist_id = new.artist_id
  ) then
    raise exception 'Funding application organization must belong to the same artist';
  end if;

  if new.project_id is not null and new.organization_id is not null and exists (
    select 1 from public.projects p
    where p.id = new.project_id
      and p.organization_id is not null
      and p.organization_id <> new.organization_id
  ) then
    raise exception 'Funding application organization must match the project carrier organization';
  end if;

  return new;
end;
$$;

drop trigger if exists funding_application_scope_guard on public.funding_applications;
create trigger funding_application_scope_guard
before insert or update of artist_id, project_id, organization_id
on public.funding_applications
for each row execute function public.validate_funding_application_scope();

comment on function public.validate_funding_application_scope() is
'Prevents funding applications from referencing projects or organizations outside the owning artist and enforces the selected project carrier when present.';

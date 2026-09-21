-- Persist the legal/administrative organization carrying each project.
alter table public.projects add column if not exists organization_id uuid references public.organizations(id) on delete set null;
create index if not exists projects_organization_idx on public.projects(organization_id);

create or replace function public.validate_project_organization()
returns trigger language plpgsql set search_path=public as $$
begin
 if new.organization_id is not null and not exists(
  select 1 from public.organizations o where o.id=new.organization_id and o.artist_id=new.artist_id
 ) then raise exception 'Project organization must belong to the same artist';
 end if;
 return new;
end $$;
drop trigger if exists projects_validate_organization on public.projects;
create trigger projects_validate_organization before insert or update of organization_id,artist_id on public.projects
for each row execute function public.validate_project_organization();
comment on column public.projects.organization_id is 'Legal/administrative organization carrying this project. Null means not selected, never inferred.';

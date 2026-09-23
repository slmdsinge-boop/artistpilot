-- entity_facts uses a polymorphic subject_id, so PostgreSQL cannot express a normal
-- foreign key to every possible subject table. Migration 0045 validates inserts and
-- updates; these delete triggers complete the lifecycle by removing facts when their
-- concrete subject is intentionally deleted.

do $$
begin
  if exists (
    select 1 from public.entity_facts ef
    where (ef.subject_type='project' and not exists (
      select 1 from public.projects p where p.id=ef.subject_id and p.artist_id=ef.artist_id
    ))
    or (ef.subject_type='organization' and not exists (
      select 1 from public.organizations o where o.id=ef.subject_id and o.artist_id=ef.artist_id
    ))
    or (ef.subject_type='application' and not exists (
      select 1 from public.funding_applications fa where fa.id=ef.subject_id and fa.artist_id=ef.artist_id
    ))
  ) then
    raise exception 'entity fact orphan preflight failed: review existing orphan facts before migration 0071';
  end if;
end $$;

create or replace function public.cleanup_entity_facts_for_deleted_subject()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  delete from public.entity_facts
  where artist_id = old.artist_id
    and subject_type = tg_argv[0]
    and subject_id = old.id;
  return old;
end;
$$;

drop trigger if exists project_entity_facts_cleanup on public.projects;
create trigger project_entity_facts_cleanup
after delete on public.projects
for each row execute function public.cleanup_entity_facts_for_deleted_subject('project');

drop trigger if exists organization_entity_facts_cleanup on public.organizations;
create trigger organization_entity_facts_cleanup
after delete on public.organizations
for each row execute function public.cleanup_entity_facts_for_deleted_subject('organization');

drop trigger if exists application_entity_facts_cleanup on public.funding_applications;
create trigger application_entity_facts_cleanup
after delete on public.funding_applications
for each row execute function public.cleanup_entity_facts_for_deleted_subject('application');

comment on function public.cleanup_entity_facts_for_deleted_subject() is
'Deletes polymorphic entity facts after their project, organization, or funding application subject is deleted; artist facts remain covered by artist_id cascade.';

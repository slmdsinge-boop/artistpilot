-- Preserve the project identity attached to historical funding applications.
-- funding_applications.project_id uses ON DELETE SET NULL, so without this guard
-- deleting a project could silently detach its funding history.

create or replace function public.guard_project_funding_history_delete()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  if exists (
    select 1
    from public.funding_applications fa
    where fa.project_id = old.id
  )
  then
    raise exception 'Project cannot be deleted while funding application history exists';
  end if;

  return old;
end;
$$;

drop trigger if exists project_funding_history_delete_guard on public.projects;
create trigger project_funding_history_delete_guard
before delete on public.projects
for each row execute function public.guard_project_funding_history_delete();

comment on function public.guard_project_funding_history_delete() is
'Prevents deleting a project referenced by funding applications, preserving historical project scope.';

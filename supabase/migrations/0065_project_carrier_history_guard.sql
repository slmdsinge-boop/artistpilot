-- Protect funding history when changing a project's carrier directly through the API.
-- Server actions already reject this change; this trigger mirrors the invariant at
-- the database boundary so existing applications cannot be detached from their
-- administrative carrier context.

create or replace function public.guard_project_carrier_history()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  if new.organization_id is distinct from old.organization_id
     and exists (
       select 1
       from public.funding_applications fa
       where fa.project_id = old.id
     )
  then
    raise exception 'Project carrier cannot change while funding application history exists';
  end if;

  return new;
end;
$$;

drop trigger if exists project_carrier_history_guard on public.projects;
create trigger project_carrier_history_guard
before update of organization_id on public.projects
for each row execute function public.guard_project_carrier_history();

comment on function public.guard_project_carrier_history() is
'Prevents changing a project carrier after funding applications exist, preserving historical funding scope even for direct API writes.';

-- Preserve the administrative identity of organizations referenced by funding history.
-- funding_applications.organization_id uses ON DELETE SET NULL, so without this guard
-- deleting an organization could silently erase the carrier from historical applications.

create or replace function public.guard_organization_funding_history()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  if exists (
    select 1
    from public.funding_applications fa
    where fa.organization_id = old.id
  )
  then
    raise exception 'Organization cannot be deleted while funding application history exists';
  end if;

  return old;
end;
$$;

drop trigger if exists organization_funding_history_guard on public.organizations;
create trigger organization_funding_history_guard
before delete on public.organizations
for each row execute function public.guard_organization_funding_history();

comment on function public.guard_organization_funding_history() is
'Prevents deleting an organization referenced directly by funding applications, preserving historical administrative scope.';

-- Preserve post-award audit history at the database trust boundary.
-- funding_obligations currently cascade on application deletion, so an authenticated
-- direct API DELETE could otherwise erase an awarded dossier and all of its evidence/tasks.

create or replace function public.guard_funding_application_delete()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  if old.status = 'awarded'
     or exists (
       select 1
       from public.funding_obligations fo
       where fo.funding_application_id = old.id
     ) then
    raise exception 'Awarded funding applications or applications with post-award obligations cannot be deleted';
  end if;

  return old;
end;
$$;

drop trigger if exists funding_applications_guard_delete on public.funding_applications;
create trigger funding_applications_guard_delete
before delete on public.funding_applications
for each row execute function public.guard_funding_application_delete();

comment on function public.guard_funding_application_delete() is
'Preserves awarded funding history and post-award obligations from direct deletion; non-awarded applications without obligations remain deletable.';

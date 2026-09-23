-- Mirror the project-carrier invariant at the funding application database boundary.
-- When an application references a project, its organization must be exactly the
-- project's persisted carrier organization, including the null/no-carrier case.

do $$
begin
  if exists (
    select 1
    from public.funding_applications fa
    join public.projects p on p.id = fa.project_id
    where fa.project_id is not null
      and fa.organization_id is distinct from p.organization_id
  ) then
    raise exception 'funding application carrier preflight failed: existing application organization differs from project carrier';
  end if;
end $$;

create or replace function public.validate_funding_application_scope()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
declare
  project_carrier uuid;
begin
  if new.project_id is not null then
    select p.organization_id into project_carrier
    from public.projects p
    where p.id = new.project_id
      and p.artist_id = new.artist_id;

    if not found then
      raise exception 'Funding application project must belong to the same artist';
    end if;

    if new.organization_id is distinct from project_carrier then
      raise exception 'Funding application organization must exactly match the project carrier organization';
    end if;
  end if;

  if new.organization_id is not null and not exists (
    select 1 from public.organizations o
    where o.id = new.organization_id and o.artist_id = new.artist_id
  ) then
    raise exception 'Funding application organization must belong to the same artist';
  end if;

  return new;
end;
$$;

comment on function public.validate_funding_application_scope() is
'Keeps funding applications inside the owning artist scope and requires exact equality with the persisted project carrier, including null.';

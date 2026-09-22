-- Enforce organization domain invariants at the database trust boundary.
-- Mirrors the existing Server Action validation so direct API writes cannot
-- create organization records the application itself would reject.

do $$
begin
  if exists (
    select 1 from public.organizations
    where organization_type not in ('association','societe','label','producteur','micro_entreprise','autre')
       or (siret is not null and siret !~ '^[0-9]{14}$')
       or (founded_on is not null and founded_on > (now() at time zone 'Europe/Paris')::date)
  ) then
    raise exception 'Existing organization data violates canonical organization domain constraints';
  end if;
end $$;

alter table public.organizations drop constraint if exists organizations_type_canonical;
alter table public.organizations add constraint organizations_type_canonical
check (organization_type in ('association','societe','label','producteur','micro_entreprise','autre'));

alter table public.organizations drop constraint if exists organizations_siret_format;
alter table public.organizations add constraint organizations_siret_format
check (siret is null or siret ~ '^[0-9]{14}$');

create or replace function public.validate_organization_founded_on()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  if new.founded_on is not null
     and new.founded_on > (now() at time zone 'Europe/Paris')::date then
    raise exception 'Organization founding date cannot be in the future';
  end if;
  return new;
end;
$$;

drop trigger if exists organizations_validate_founded_on on public.organizations;
create trigger organizations_validate_founded_on
before insert or update of founded_on on public.organizations
for each row execute function public.validate_organization_founded_on();

comment on constraint organizations_type_canonical on public.organizations is
'Database mirror of the canonical ArtistPilot organization-type vocabulary.';

comment on constraint organizations_siret_format on public.organizations is
'SIRET is unknown/null or exactly fourteen digits.';

comment on function public.validate_organization_founded_on() is
'Rejects organization founding dates after the current Europe/Paris calendar date.';

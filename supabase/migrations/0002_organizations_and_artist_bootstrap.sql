-- ArtistPilot V1: secure artist bootstrap and functional organizations.
-- Keeps users, artists and legal organizations as separate entities.

alter table public.organizations
  add column if not exists artist_id uuid references public.artist_profiles(id) on delete cascade;

create index if not exists organizations_artist_id_idx
  on public.organizations(artist_id);

drop policy if exists "organizations visible through artist access" on public.organizations;
create policy "organizations visible through artist access" on public.organizations
for select using (
  artist_id is not null
  and exists (
    select 1 from public.user_artist_access a
    where a.artist_id = organizations.artist_id
      and a.user_id = auth.uid()
  )
);

drop policy if exists "organizations insertable through artist access" on public.organizations;
create policy "organizations insertable through artist access" on public.organizations
for insert with check (
  artist_id is not null
  and exists (
    select 1 from public.user_artist_access a
    where a.artist_id = organizations.artist_id
      and a.user_id = auth.uid()
  )
);

drop policy if exists "organizations editable through artist access" on public.organizations;
create policy "organizations editable through artist access" on public.organizations
for update using (
  artist_id is not null
  and exists (
    select 1 from public.user_artist_access a
    where a.artist_id = organizations.artist_id
      and a.user_id = auth.uid()
  )
) with check (
  artist_id is not null
  and exists (
    select 1 from public.user_artist_access a
    where a.artist_id = organizations.artist_id
      and a.user_id = auth.uid()
  )
);

drop policy if exists "organizations deletable through artist access" on public.organizations;
create policy "organizations deletable through artist access" on public.organizations
for delete using (
  artist_id is not null
  and exists (
    select 1 from public.user_artist_access a
    where a.artist_id = organizations.artist_id
      and a.user_id = auth.uid()
  )
);

create or replace function public.bootstrap_artist_profile(display_name text default null)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  existing_artist_id uuid;
  new_artist_id uuid;
  safe_name text;
begin
  if current_user_id is null then
    raise exception 'Authentication required';
  end if;

  select artist_id
    into existing_artist_id
  from public.user_artist_access
  where user_id = current_user_id
  order by artist_id
  limit 1;

  if existing_artist_id is not null then
    return existing_artist_id;
  end if;

  safe_name := nullif(trim(display_name), '');
  if safe_name is null then
    safe_name := 'Mon profil artiste';
  end if;

  insert into public.artist_profiles(name)
  values (safe_name)
  returning id into new_artist_id;

  insert into public.user_artist_access(user_id, artist_id, role)
  values (current_user_id, new_artist_id, 'owner');

  return new_artist_id;
end;
$$;

revoke all on function public.bootstrap_artist_profile(text) from public;
grant execute on function public.bootstrap_artist_profile(text) to authenticated;

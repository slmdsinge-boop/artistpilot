-- ArtistPilot V1: make Projects a usable, secure domain entity.

alter table public.projects
  add column if not exists description text,
  add column if not exists start_date date,
  add column if not exists target_date date,
  add column if not exists updated_at timestamptz not null default now();

create index if not exists projects_artist_id_idx on public.projects(artist_id);
create index if not exists projects_organization_id_idx on public.projects(organization_id);

drop policy if exists "projects insertable through artist access" on public.projects;
create policy "projects insertable through artist access" on public.projects
for insert with check (
  exists (
    select 1 from public.user_artist_access a
    where a.artist_id = projects.artist_id and a.user_id = auth.uid()
  )
  and (
    projects.organization_id is null
    or exists (
      select 1 from public.organizations o
      join public.user_artist_access a on a.artist_id = o.artist_id
      where o.id = projects.organization_id
        and o.artist_id = projects.artist_id
        and a.user_id = auth.uid()
    )
  )
);

drop policy if exists "projects editable through artist access" on public.projects;
create policy "projects editable through artist access" on public.projects
for update using (
  exists (
    select 1 from public.user_artist_access a
    where a.artist_id = projects.artist_id and a.user_id = auth.uid()
  )
) with check (
  exists (
    select 1 from public.user_artist_access a
    where a.artist_id = projects.artist_id and a.user_id = auth.uid()
  )
  and (
    projects.organization_id is null
    or exists (
      select 1 from public.organizations o
      join public.user_artist_access a on a.artist_id = o.artist_id
      where o.id = projects.organization_id
        and o.artist_id = projects.artist_id
        and a.user_id = auth.uid()
    )
  )
);

drop policy if exists "projects deletable through artist access" on public.projects;
create policy "projects deletable through artist access" on public.projects
for delete using (
  exists (
    select 1 from public.user_artist_access a
    where a.artist_id = projects.artist_id and a.user_id = auth.uid()
  )
);

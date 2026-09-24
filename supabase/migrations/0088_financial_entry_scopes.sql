-- Link financial movements to an optional project and/or organization.
alter table public.financial_entries
  add column if not exists project_id uuid references public.projects(id) on delete set null,
  add column if not exists organization_id uuid references public.organizations(id) on delete set null;

create index if not exists financial_entries_project_id_idx on public.financial_entries(project_id);
create index if not exists financial_entries_organization_id_idx on public.financial_entries(organization_id);

alter table public.financial_entries
  add constraint financial_entries_project_artist_guard
  check (project_id is null or artist_id is not null);

-- Cross-entity ownership is enforced by the write policy.
drop policy if exists "financial_entries_insert_access" on public.financial_entries;
create policy "financial_entries_insert_access" on public.financial_entries for insert with check (
  exists(select 1 from public.user_artist_access a where a.artist_id=financial_entries.artist_id and a.user_id=auth.uid())
  and (project_id is null or exists(select 1 from public.projects p where p.id=project_id and p.artist_id=financial_entries.artist_id))
  and (organization_id is null or exists(select 1 from public.organizations o where o.id=organization_id and o.artist_id=financial_entries.artist_id))
);

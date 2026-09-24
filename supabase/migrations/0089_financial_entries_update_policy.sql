-- Allow users to edit financial movements while preserving artist ownership and linked scopes.
drop policy if exists "financial_entries_update_access" on public.financial_entries;
create policy "financial_entries_update_access" on public.financial_entries
for update
using (
  exists (
    select 1 from public.user_artist_access a
    where a.artist_id = financial_entries.artist_id
      and a.user_id = auth.uid()
  )
)
with check (
  exists (
    select 1 from public.user_artist_access a
    where a.artist_id = financial_entries.artist_id
      and a.user_id = auth.uid()
  )
  and (
    project_id is null
    or exists (
      select 1 from public.projects p
      where p.id = project_id
        and p.artist_id = financial_entries.artist_id
    )
  )
  and (
    organization_id is null
    or exists (
      select 1 from public.organizations o
      where o.id = organization_id
        and o.artist_id = financial_entries.artist_id
    )
  )
);

create table if not exists public.works (
  id uuid primary key default gen_random_uuid(),
  artist_id uuid not null references public.artist_profiles(id) on delete cascade,
  title text not null check (char_length(title) between 1 and 180),
  work_type text not null default 'song' check (work_type in ('song','composition','recording','other')),
  status text not null default 'draft' check (status in ('draft','ready','released')),
  sacem_status text not null default 'to_do' check (sacem_status in ('to_do','declared','not_applicable')),
  release_date date,
  notes text check (notes is null or char_length(notes) <= 1000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.works enable row level security;
create policy "works_select_access" on public.works for select using (exists(select 1 from public.user_artist_access a where a.artist_id=works.artist_id and a.user_id=auth.uid()));
create policy "works_insert_access" on public.works for insert with check (exists(select 1 from public.user_artist_access a where a.artist_id=works.artist_id and a.user_id=auth.uid()));
create policy "works_update_access" on public.works for update using (exists(select 1 from public.user_artist_access a where a.artist_id=works.artist_id and a.user_id=auth.uid())) with check (exists(select 1 from public.user_artist_access a where a.artist_id=works.artist_id and a.user_id=auth.uid()));
create policy "works_delete_access" on public.works for delete using (exists(select 1 from public.user_artist_access a where a.artist_id=works.artist_id and a.user_id=auth.uid()));
create index if not exists works_artist_created_idx on public.works(artist_id, created_at desc);

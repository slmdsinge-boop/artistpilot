-- Concerts V1: artist-owned performance tracking for dates, fees and intermittence inputs.

create table public.concerts (
  id uuid primary key default gen_random_uuid(),
  artist_id uuid not null references public.artist_profiles(id) on delete cascade,
  project_id uuid references public.projects(id) on delete set null,
  organization_id uuid references public.organizations(id) on delete set null,
  title text not null,
  venue text,
  city text,
  performance_date date not null,
  status text not null default 'planned',
  fee_eur numeric(12,2),
  paid_hours numeric(8,2),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint concerts_title_length check (char_length(btrim(title)) between 1 and 240),
  constraint concerts_status_domain check (status in ('planned','confirmed','completed','cancelled')),
  constraint concerts_fee_nonnegative check (fee_eur is null or fee_eur >= 0),
  constraint concerts_hours_nonnegative check (paid_hours is null or paid_hours >= 0),
  constraint concerts_notes_length check (notes is null or char_length(notes) <= 5000)
);

create index concerts_artist_date_idx on public.concerts(artist_id, performance_date desc);
create index concerts_project_idx on public.concerts(project_id) where project_id is not null;

alter table public.concerts enable row level security;

create policy "concerts visible through artist access" on public.concerts
for select using (
  exists (select 1 from public.user_artist_access a where a.artist_id=concerts.artist_id and a.user_id=auth.uid())
);

create policy "concerts insert through artist access" on public.concerts
for insert with check (
  exists (select 1 from public.user_artist_access a where a.artist_id=concerts.artist_id and a.user_id=auth.uid())
  and (project_id is null or exists (select 1 from public.projects p where p.id=project_id and p.artist_id=concerts.artist_id))
  and (organization_id is null or exists (select 1 from public.organizations o where o.id=organization_id and o.artist_id=concerts.artist_id))
);

create policy "concerts update through artist access" on public.concerts
for update using (
  exists (select 1 from public.user_artist_access a where a.artist_id=concerts.artist_id and a.user_id=auth.uid())
) with check (
  exists (select 1 from public.user_artist_access a where a.artist_id=concerts.artist_id and a.user_id=auth.uid())
  and (project_id is null or exists (select 1 from public.projects p where p.id=project_id and p.artist_id=concerts.artist_id))
  and (organization_id is null or exists (select 1 from public.organizations o where o.id=organization_id and o.artist_id=concerts.artist_id))
);

create policy "concerts delete through artist access" on public.concerts
for delete using (
  exists (select 1 from public.user_artist_access a where a.artist_id=concerts.artist_id and a.user_id=auth.uid())
);

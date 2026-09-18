create extension if not exists "pgcrypto";

-- ArtistPilot V1 initial schema.
-- Idempotent baseline: safe to adopt an already partially-created V1 database.
-- Regulatory truth remains deterministic, sourced and versioned separately.

create table if not exists public.artist_profiles (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  bio text,
  created_at timestamptz not null default now()
);

create table if not exists public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text,
  organization_type text not null,
  siret text,
  created_at timestamptz not null default now()
);

create table if not exists public.user_artist_access (
  user_id uuid not null references auth.users(id) on delete cascade,
  artist_id uuid not null references public.artist_profiles(id) on delete cascade,
  role text not null default 'owner',
  primary key (user_id, artist_id)
);

create table if not exists public.projects (
  id uuid primary key default gen_random_uuid(),
  artist_id uuid not null references public.artist_profiles(id) on delete cascade,
  organization_id uuid references public.organizations(id) on delete set null,
  name text not null,
  project_type text not null,
  status text not null default 'active',
  created_at timestamptz not null default now()
);

alter table public.artist_profiles enable row level security;
alter table public.organizations enable row level security;
alter table public.user_artist_access enable row level security;
alter table public.projects enable row level security;

drop policy if exists "artists visible to members" on public.artist_profiles;
create policy "artists visible to members" on public.artist_profiles
for select using (
  exists (
    select 1 from public.user_artist_access a
    where a.artist_id = artist_profiles.id and a.user_id = auth.uid()
  )
);

drop policy if exists "access rows visible to self" on public.user_artist_access;
create policy "access rows visible to self" on public.user_artist_access
for select using (user_id = auth.uid());

drop policy if exists "projects visible through artist access" on public.projects;
create policy "projects visible through artist access" on public.projects
for select using (
  exists (
    select 1 from public.user_artist_access a
    where a.artist_id = projects.artist_id and a.user_id = auth.uid()
  )
);

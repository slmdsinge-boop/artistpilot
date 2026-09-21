-- ArtistPilot V1: funding catalogue and applications.
-- Regulatory truth is stored with an official source and verification state.

create table if not exists public.funding_programs (
  id uuid primary key default gen_random_uuid(),
  provider_name text not null,
  name text not null,
  description text,
  official_url text not null,
  funding_types text[] not null default '{}',
  project_types text[] not null default '{}',
  applicant_types text[] not null default '{}',
  deadline_date date,
  deadline_text text,
  max_amount_eur numeric(12,2),
  eligibility_notes text,
  verification_status text not null default 'to_verify'
    check (verification_status in ('to_verify','verified','archived')),
  verified_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.funding_applications (
  id uuid primary key default gen_random_uuid(),
  artist_id uuid not null references public.artist_profiles(id) on delete cascade,
  project_id uuid references public.projects(id) on delete set null,
  organization_id uuid references public.organizations(id) on delete set null,
  funding_program_id uuid not null references public.funding_programs(id) on delete restrict,
  status text not null default 'identified'
    check (status in ('identified','to_check','eligible','preparing','submitted','awarded','rejected','withdrawn')),
  requested_amount_eur numeric(12,2),
  awarded_amount_eur numeric(12,2),
  submitted_at date,
  decision_at date,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists funding_applications_artist_id_idx on public.funding_applications(artist_id);
create index if not exists funding_applications_project_id_idx on public.funding_applications(project_id);
create index if not exists funding_programs_deadline_idx on public.funding_programs(deadline_date);

alter table public.funding_programs enable row level security;
alter table public.funding_applications enable row level security;

drop policy if exists "verified funding programs readable by authenticated users" on public.funding_programs;
create policy "verified funding programs readable by authenticated users" on public.funding_programs
for select using (auth.uid() is not null);

drop policy if exists "funding applications readable through artist access" on public.funding_applications;
create policy "funding applications readable through artist access" on public.funding_applications
for select using (
  exists (select 1 from public.user_artist_access a where a.artist_id=funding_applications.artist_id and a.user_id=auth.uid())
);

drop policy if exists "funding applications insertable through artist access" on public.funding_applications;
create policy "funding applications insertable through artist access" on public.funding_applications
for insert with check (
  exists (select 1 from public.user_artist_access a where a.artist_id=funding_applications.artist_id and a.user_id=auth.uid())
);

drop policy if exists "funding applications editable through artist access" on public.funding_applications;
create policy "funding applications editable through artist access" on public.funding_applications
for update using (
  exists (select 1 from public.user_artist_access a where a.artist_id=funding_applications.artist_id and a.user_id=auth.uid())
) with check (
  exists (select 1 from public.user_artist_access a where a.artist_id=funding_applications.artist_id and a.user_id=auth.uid())
);

drop policy if exists "funding applications deletable through artist access" on public.funding_applications;
create policy "funding applications deletable through artist access" on public.funding_applications
for delete using (
  exists (select 1 from public.user_artist_access a where a.artist_id=funding_applications.artist_id and a.user_id=auth.uid())
);

-- Administrative facts used by the eligibility engine.
-- Nullable booleans intentionally mean "unknown", never false by default.
alter table public.organizations
  add column if not exists cnm_affiliated boolean,
  add column if not exists sacem_affiliated boolean,
  add column if not exists adami_affiliated boolean,
  add column if not exists spedidam_affiliated boolean,
  add column if not exists scpp_affiliated boolean,
  add column if not exists sppf_affiliated boolean,
  add column if not exists spectacle_licence boolean,
  add column if not exists employs_artists boolean,
  add column if not exists phonogram_producer boolean,
  add column if not exists owns_masters boolean,
  add column if not exists founded_on date,
  add column if not exists admin_notes text,
  add column if not exists updated_at timestamptz not null default now();

alter table public.projects
  add column if not exists budget_eur numeric(12,2),
  add column if not exists performance_count integer,
  add column if not exists artist_count integer,
  add column if not exists international boolean,
  add column if not exists recording_started boolean,
  add column if not exists recording_finished boolean;

alter table public.projects drop constraint if exists projects_performance_count_nonnegative;
alter table public.projects add constraint projects_performance_count_nonnegative check (performance_count is null or performance_count >= 0);
alter table public.projects drop constraint if exists projects_artist_count_nonnegative;
alter table public.projects add constraint projects_artist_count_nonnegative check (artist_count is null or artist_count >= 0);

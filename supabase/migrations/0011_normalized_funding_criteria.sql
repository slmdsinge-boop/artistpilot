-- Normalized, source-backed criteria model.
-- No criterion is executable until it has been explicitly verified.
create table if not exists public.funding_criteria (
  id uuid primary key default gen_random_uuid(),
  funding_program_id uuid not null references public.funding_programs(id) on delete cascade,
  criterion_key text not null,
  subject_type text not null check (subject_type in ('artist','organization','project','application')),
  operator text not null check (operator in ('eq','neq','gte','lte','gt','lt','in','not_null')),
  expected_value jsonb,
  required boolean not null default true,
  blocking boolean not null default true,
  source_text text,
  source_url text,
  verification_status text not null default 'to_verify' check (verification_status in ('to_verify','verified','archived')),
  source_checked_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(funding_program_id, criterion_key)
);

alter table public.funding_criteria enable row level security;

drop policy if exists "Authenticated users can read funding criteria" on public.funding_criteria;
create policy "Authenticated users can read funding criteria"
on public.funding_criteria for select to authenticated using (true);

create index if not exists funding_criteria_program_idx on public.funding_criteria(funding_program_id);
create index if not exists funding_criteria_verified_idx on public.funding_criteria(verification_status);

comment on table public.funding_criteria is
'Atomic eligibility criteria backed by an official source. Only verified criteria may be used by the deterministic eligibility engine.';
comment on column public.funding_criteria.source_text is
'Short factual paraphrase of the official criterion; never inferred from a program name.';
comment on column public.funding_criteria.source_checked_at is
'When the official source supporting this criterion was last checked.';

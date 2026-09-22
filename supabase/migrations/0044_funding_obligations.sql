-- User-entered post-award obligations and evidence tracking.
-- No obligation is created automatically from a funding program: rows represent facts/tasks explicitly recorded by the user.
create table if not exists public.funding_obligations (
  id uuid primary key default gen_random_uuid(),
  artist_id uuid not null references public.artist_profiles(id) on delete cascade,
  funding_application_id uuid not null references public.funding_applications(id) on delete cascade,
  title text not null check (char_length(trim(title)) between 1 and 240),
  due_date date,
  status text not null default 'to_do' check (status in ('to_do','in_progress','done','not_applicable')),
  notes text check (notes is null or char_length(notes) <= 5000),
  completed_at date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint funding_obligations_completion_consistency check ((status='done' and completed_at is not null) or (status<>'done' and completed_at is null))
);

create index if not exists funding_obligations_artist_idx on public.funding_obligations(artist_id);
create index if not exists funding_obligations_application_idx on public.funding_obligations(funding_application_id);
create index if not exists funding_obligations_due_idx on public.funding_obligations(due_date) where status in ('to_do','in_progress');

alter table public.funding_obligations enable row level security;

drop policy if exists funding_obligations_select_own on public.funding_obligations;
create policy funding_obligations_select_own on public.funding_obligations for select to authenticated using (exists(select 1 from public.artist_profiles a where a.id=artist_id and exists(select 1 from public.user_artist_access uaa where uaa.artist_id=a.id and uaa.user_id=auth.uid())));
drop policy if exists funding_obligations_insert_own on public.funding_obligations;
create policy funding_obligations_insert_own on public.funding_obligations for insert to authenticated with check (exists(select 1 from public.artist_profiles a where a.id=funding_obligations.artist_id and exists(select 1 from public.user_artist_access uaa where uaa.artist_id=a.id and uaa.user_id=auth.uid())) and exists(select 1 from public.funding_applications fa where fa.id=funding_obligations.funding_application_id and fa.artist_id=funding_obligations.artist_id));
drop policy if exists funding_obligations_update_own on public.funding_obligations;
create policy funding_obligations_update_own on public.funding_obligations for update to authenticated using (exists(select 1 from public.artist_profiles a where a.id=funding_obligations.artist_id and exists(select 1 from public.user_artist_access uaa where uaa.artist_id=a.id and uaa.user_id=auth.uid()))) with check (exists(select 1 from public.artist_profiles a where a.id=funding_obligations.artist_id and exists(select 1 from public.user_artist_access uaa where uaa.artist_id=a.id and uaa.user_id=auth.uid())) and exists(select 1 from public.funding_applications fa where fa.id=funding_obligations.funding_application_id and fa.artist_id=funding_obligations.artist_id));
drop policy if exists funding_obligations_delete_own on public.funding_obligations;
create policy funding_obligations_delete_own on public.funding_obligations for delete to authenticated using (exists(select 1 from public.artist_profiles a where a.id=artist_id and exists(select 1 from public.user_artist_access uaa where uaa.artist_id=a.id and uaa.user_id=auth.uid())));

comment on table public.funding_obligations is 'Post-award administrative obligations explicitly recorded by the user; never inferred automatically without a sourced rule.';

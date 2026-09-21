-- Generic user-confirmed fact store for eligibility engine V2.
-- Avoids adding one database column for every funding-program criterion.
create table if not exists public.entity_facts (
 id uuid primary key default gen_random_uuid(),
 artist_id uuid not null references public.artist_profiles(id) on delete cascade,
 subject_type text not null check(subject_type in ('artist','organization','project','application')),
 subject_id uuid not null,
 fact_key text not null,
 value jsonb not null,
 confirmation_status text not null default 'user_confirmed' check(confirmation_status in ('user_confirmed','document_confirmed','derived')),
 source_note text,
 confirmed_at timestamptz not null default now(),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 unique(artist_id,subject_type,subject_id,fact_key)
);
alter table public.entity_facts enable row level security;
drop policy if exists "Users read own eligibility facts" on public.entity_facts;
create policy "Users read own eligibility facts" on public.entity_facts for select to authenticated
using (artist_id in (select artist_id from public.user_artist_access where user_id=auth.uid()));
drop policy if exists "Users insert own eligibility facts" on public.entity_facts;
create policy "Users insert own eligibility facts" on public.entity_facts for insert to authenticated
with check (artist_id in (select artist_id from public.user_artist_access where user_id=auth.uid()));
drop policy if exists "Users update own eligibility facts" on public.entity_facts;
create policy "Users update own eligibility facts" on public.entity_facts for update to authenticated
using (artist_id in (select artist_id from public.user_artist_access where user_id=auth.uid()))
with check (artist_id in (select artist_id from public.user_artist_access where user_id=auth.uid()));
drop policy if exists "Users delete own eligibility facts" on public.entity_facts;
create policy "Users delete own eligibility facts" on public.entity_facts for delete to authenticated
using (artist_id in (select artist_id from public.user_artist_access where user_id=auth.uid()));
create index if not exists entity_facts_subject_idx on public.entity_facts(artist_id,subject_type,subject_id);
create index if not exists entity_facts_key_idx on public.entity_facts(fact_key);
comment on table public.entity_facts is 'User/document-confirmed facts consumed by funding eligibility engine V2. Absence means unknown, never false.';

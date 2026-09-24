create table if not exists public.financial_entries (
 id uuid primary key default gen_random_uuid(), artist_id uuid not null references public.artists(id) on delete cascade,
 entry_type text not null check (entry_type in ('income','expense')), category text, label text not null,
 amount_eur numeric(12,2) not null check (amount_eur >= 0), entry_date date not null, notes text, created_at timestamptz not null default now());
alter table public.financial_entries enable row level security;
create policy "financial_entries_select_access" on public.financial_entries for select using (exists(select 1 from public.user_artist_access a where a.artist_id=financial_entries.artist_id and a.user_id=auth.uid()));
create policy "financial_entries_insert_access" on public.financial_entries for insert with check (exists(select 1 from public.user_artist_access a where a.artist_id=financial_entries.artist_id and a.user_id=auth.uid()));
create policy "financial_entries_delete_access" on public.financial_entries for delete using (exists(select 1 from public.user_artist_access a where a.artist_id=financial_entries.artist_id and a.user_id=auth.uid()));
create index if not exists financial_entries_artist_date_idx on public.financial_entries(artist_id,entry_date desc);
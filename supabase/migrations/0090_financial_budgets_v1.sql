create table if not exists public.financial_budgets (
  id uuid primary key default gen_random_uuid(),
  artist_id uuid not null references public.artist_profiles(id) on delete cascade,
  budget_year integer not null check (budget_year between 2000 and 2100),
  income_target_eur numeric(12,2) not null default 0 check (income_target_eur >= 0),
  expense_limit_eur numeric(12,2) not null default 0 check (expense_limit_eur >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (artist_id, budget_year)
);

alter table public.financial_budgets enable row level security;

create policy "financial_budgets_select_access" on public.financial_budgets for select using (
  exists (select 1 from public.user_artist_access a where a.artist_id = financial_budgets.artist_id and a.user_id = auth.uid())
);
create policy "financial_budgets_insert_access" on public.financial_budgets for insert with check (
  exists (select 1 from public.user_artist_access a where a.artist_id = financial_budgets.artist_id and a.user_id = auth.uid())
);
create policy "financial_budgets_update_access" on public.financial_budgets for update using (
  exists (select 1 from public.user_artist_access a where a.artist_id = financial_budgets.artist_id and a.user_id = auth.uid())
) with check (
  exists (select 1 from public.user_artist_access a where a.artist_id = financial_budgets.artist_id and a.user_id = auth.uid())
);

create index if not exists financial_budgets_artist_year_idx on public.financial_budgets(artist_id, budget_year);

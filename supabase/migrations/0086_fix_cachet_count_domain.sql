-- The regulatory 28-cachet limit applies per calendar month, not per concert row.
-- Monthly capping is handled by the intermittence estimate; keep the stored value non-negative.
alter table public.concerts
  drop constraint if exists concerts_cachet_count_domain;

alter table public.concerts
  add constraint concerts_cachet_count_domain
  check (cachet_count is null or cachet_count >= 0);

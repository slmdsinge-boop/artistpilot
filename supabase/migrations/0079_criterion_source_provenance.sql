-- A criterion marked verified is executable by the eligibility engine. Require
-- temporal and navigable provenance at the database boundary, not only in seeds.
-- Existing rows are preflighted instead of silently backfilled.

do $$
begin
  if exists (
    select 1
    from public.funding_criteria
    where verification_status = 'verified'
      and (
        source_checked_at is null
        or source_url is null
        or btrim(source_url) = ''
        or source_text is null
        or btrim(source_text) = ''
      )
  ) then
    raise exception 'verified funding criterion provenance preflight failed: review missing source date, URL, or source text';
  end if;
end $$;

alter table public.funding_criteria
  drop constraint if exists funding_criteria_verified_provenance;

alter table public.funding_criteria
  add constraint funding_criteria_verified_provenance
  check (
    verification_status <> 'verified'
    or (
      source_checked_at is not null
      and source_url is not null
      and btrim(source_url) <> ''
      and source_text is not null
      and btrim(source_text) <> ''
    )
  );

comment on constraint funding_criteria_verified_provenance on public.funding_criteria is
'Executable verified criteria must retain a source check timestamp, source URL, and factual source paraphrase.';

-- A funding program marked verified must carry a verification timestamp.
-- Readiness/freshness logic depends on explicit provenance; direct database/API writes
-- must not create a nominally verified program with no recorded verification event.

do $$
begin
  if exists (
    select 1
    from public.funding_programs
    where verification_status = 'verified'
      and verified_at is null
  ) then
    raise exception 'funding program verification provenance preflight failed: verified program without verified_at';
  end if;
end $$;

alter table public.funding_programs
  drop constraint if exists funding_programs_verified_at_required;

alter table public.funding_programs
  add constraint funding_programs_verified_at_required
  check (verification_status <> 'verified' or verified_at is not null);

comment on constraint funding_programs_verified_at_required on public.funding_programs is
'Verified funding programs require an explicit verification timestamp; freshness remains separately governed by source_checked_at.';

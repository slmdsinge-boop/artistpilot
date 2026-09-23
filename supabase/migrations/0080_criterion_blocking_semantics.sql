-- Only eligibility criteria participate in deterministic blocking decisions.
-- Encode that invariant in the database so future admin/import writes cannot mark
-- calculation, document or manual criteria as blockers by mistake.
--
-- Existing non-eligibility blockers are normalized first: this is a semantic
-- correction, not loss of eligibility information, because V2.3 and trackFunding
-- already ignore them for blocking decisions.

update public.funding_criteria
set blocking = false,
    updated_at = now()
where criterion_kind <> 'eligibility'
  and blocking = true;

alter table public.funding_criteria
  drop constraint if exists funding_criteria_blocking_kind_consistency;

alter table public.funding_criteria
  add constraint funding_criteria_blocking_kind_consistency
  check (criterion_kind = 'eligibility' or blocking = false);

comment on constraint funding_criteria_blocking_kind_consistency on public.funding_criteria is
'Only eligibility criteria may block deterministic funding eligibility. Calculation, document and manual criteria are informational/workflow rules.';

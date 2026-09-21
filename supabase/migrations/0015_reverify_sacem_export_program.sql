-- Safety correction: a legacy SACEM export seed cannot remain verified
-- unless its current official program page and criteria have been re-checked.
update public.funding_programs
set verification_status='to_verify', verified_at=null,
    deadline_date=null,
    deadline_text='À re-vérifier sur la source officielle actuelle avant toute conclusion ou alerte.'
where provider_name='SACEM'
  and name='Aides aux tournées et showcases à l’international – Musiques actuelles et jazz';

-- Criteria for this program are intentionally not seeded yet.
-- Historical evidence that a similarly named program existed is not enough
-- to encode current deterministic eligibility rules.

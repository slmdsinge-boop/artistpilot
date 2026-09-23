-- Advance only deadlines whose later 2026 deposit date was already explicitly
-- recorded in verified seed data. This avoids closing a program after an earlier
-- commission while a separately verified later deposit window remains actionable.

update public.funding_programs
set deadline_date = '2026-10-30'::date,
    deadline_text = 'Date limite de dépôt actuellement actionnable : 30 octobre 2026. La date précédente enregistrée était le 30 septembre 2026.',
    updated_at = now()
where provider_name = 'CNM'
  and name = 'Aide à la production phonographique'
  and verification_status = 'verified'
  and deadline_date = '2026-09-30'::date
  and deadline_text like '%30 octobre 2026%';

update public.funding_programs
set deadline_date = '2026-12-28'::date,
    deadline_text = 'Date limite de dépôt actuellement actionnable : 28 décembre 2026, pour le comité du 28 janvier 2027. La date précédente enregistrée était le 19 octobre 2026.',
    updated_at = now()
where provider_name = 'CNM'
  and name = 'Crédit d’impôt en faveur de la production phonographique (CIPP)'
  and verification_status = 'verified'
  and deadline_date = '2026-10-19'::date
  and deadline_text like '%28 décembre 2026%';

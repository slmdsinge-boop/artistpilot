-- The verified SPPF 2026 source recorded two successive commissions. Once the
-- 7 October deadline passes, keeping it as deadline_date would incorrectly close
-- tracking even though the already-verified next deposit deadline is 19 November.
update public.funding_programs
set deadline_date = '2026-11-19'::date,
    deadline_text = 'Commission Aide à la création du 17 décembre 2026 — date limite de dépôt : 19 novembre 2026. La commission précédente du 4 novembre avait une date limite au 7 octobre.',
    updated_at = now()
where provider_name = 'SPPF'
  and name = 'Aide à la création'
  and verification_status = 'verified'
  and deadline_date = '2026-10-07'::date
  and deadline_text like '%19 novembre%';

comment on column public.funding_programs.deadline_date is
'Current actionable deposit deadline for the program. When an official source confirms successive cycles, advance this field only to a separately verified next deadline; preserve schedule context in deadline_text.';

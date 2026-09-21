-- SPEDIDAM 2026 spectacle musical criteria.
-- Official live page and 6 Jan 2026 criteria-change notice checked 2026-09-21.
insert into public.funding_criteria
(funding_program_id,criterion_key,subject_type,operator,expected_value,required,blocking,source_text,source_url,verification_status,source_checked_at)
select fp.id,v.k,v.s,v.o,v.e::jsonb,true,true,v.t,
'https://www.spedidam.fr/aides-aux-projets/nos-programmes/aide-au-spectacle-musical/',
'verified','2026-09-21T00:00:00Z'
from public.funding_programs fp cross join (values
('musical_live_project','project','eq','true','Le projet doit concerner la création/diffusion ou la diffusion d’un spectacle vivant musical relevant du programme.'),
('dates_after_commission','project','eq','true','Les dates soutenues, répétitions comprises, doivent être postérieures au dernier jour de la commission.'),
('min_performances','project','gte','6','Le projet doit proposer au moins six représentations.'),
('min_performance_days','project','gte','5','Les six représentations doivent se dérouler sur au moins cinq jours.'),
('max_rehearsals','project','lte','10','Le projet peut comprendre au maximum dix répétitions.'),
('large_ensemble_8_artists','project','eq','true','Pour un ensemble d’au moins huit artistes présents sur scène à toutes les dates, le régime 2026 permet un seuil adapté de quatre jours de représentations.'),
('direct_artist_employment','organization','eq','true','L’aide porte sur le coût total employeur des artistes-interprètes directement employés par la structure.'),
('artist_payroll_available','application','eq','true','Les salaires et charges des artistes-interprètes doivent pouvoir être justifiés par les pièces de paie requises.')
) v(k,s,o,e,t)
where fp.provider_name='SPEDIDAM' and fp.name='Aide spectacle musical'
on conflict(funding_program_id,criterion_key) do update set
subject_type=excluded.subject_type,operator=excluded.operator,expected_value=excluded.expected_value,
source_text=excluded.source_text,source_url=excluded.source_url,verification_status='verified',
source_checked_at=excluded.source_checked_at,updated_at=now();

update public.funding_programs set verification_status='verified',verified_at=now(),
official_url='https://www.spedidam.fr/aides-aux-projets/nos-programmes/aide-au-spectacle-musical/',
eligibility_notes='Critères 2026 vérifiés sur la page officielle SPEDIDAM. Les ensembles d’au moins 8 artistes présents sur scène bénéficient de conditions adaptées. Les critères non structurés restent à vérifier avant conclusion.'
where provider_name='SPEDIDAM' and name='Aide spectacle musical';

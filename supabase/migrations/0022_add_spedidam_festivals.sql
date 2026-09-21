-- Add current SPEDIDAM festival aid and deterministic criteria.
-- Official current program page checked 2026-09-21.
insert into public.funding_programs
(provider_name,name,description,official_url,funding_types,project_types,applicant_types,deadline_date,deadline_text,max_amount_eur,eligibility_notes,verification_status,verified_at)
select 'SPEDIDAM','Aide aux festivals',
'Aide à un festival de musique portant principalement sur le coût employeur des artistes-interprètes.',
'https://www.spedidam.fr/aides-aux-projets/nos-programmes/aide-aux-festivals/',
ARRAY['festival','diffusion','spectacle vivant'],ARRAY['festival'],ARRAY['structure organisatrice'],
NULL,'Dossier complet avant la date limite du calendrier de la commission SPEDIDAM.',NULL,
'Critères actuels vérifiés sur la page officielle. Une seule aide de la famille spectacle musical/dramatique/festival peut être accordée par structure et année civile.',
'verified',now()
where not exists(select 1 from public.funding_programs where provider_name='SPEDIDAM' and name='Aide aux festivals');

insert into public.funding_criteria
(funding_program_id,criterion_key,subject_type,operator,expected_value,required,blocking,source_text,source_url,verification_status,source_checked_at)
select fp.id,v.k,v.s,v.o,v.e::jsonb,true,true,v.t,fp.official_url,'verified','2026-09-21T00:00:00Z'
from public.funding_programs fp cross join (values
('music_festival','project','eq','true','La demande doit concerner un festival de musique.'),
('after_commission','project','eq','true','Les dates du projet doivent être postérieures au dernier jour de la commission.'),
('festival_duration_days','project','lte','31','La durée totale du festival ne peut excéder 31 jours consécutifs.'),
('min_performances','project','gte','6','Le festival doit proposer au moins six représentations, premières parties incluses.'),
('min_performance_days','project','gte','3','Les représentations doivent être réparties sur au moins trois jours.'),
('not_public_body','organization','eq','true','Les structures publiques et celles majoritairement contrôlées par une personne morale de droit public sont exclues.'),
('aid_share','application','lte','0.4','L’aide ne peut excéder 40 % du coût total employeur éligible.'),
('performance_fee_calculation_cap','project','lte','500','Pour le calcul de l’aide maximum, le cachet de représentation pris en compte est plafonné à 500 euros brut.'),
('signed_firm_date_contract','application','eq','true','Le dossier doit comporter une preuve signée d’engagement pour une date ferme postérieure à la commission ; les courriels ne sont pas acceptés.'),
('previous_grant_balance_requested','application','eq','true','Avant un nouveau dossier, le versement du solde de l’aide précédente doit avoir été demandé.'),
('one_live_grant_family_per_year','application','eq','true','Une seule aide spectacle musical, spectacle dramatique/chorégraphique/cirque/marionnette ou festival peut être accordée par structure et année civile.'),
('project_starts_within_six_months','project','eq','true','Le projet doit débuter au plus tard six mois après le dernier jour de la commission, sauf report autorisé.')
) v(k,s,o,e,t)
where fp.provider_name='SPEDIDAM' and fp.name='Aide aux festivals'
on conflict(funding_program_id,criterion_key) do update set subject_type=excluded.subject_type,operator=excluded.operator,expected_value=excluded.expected_value,source_text=excluded.source_text,source_url=excluded.source_url,verification_status='verified',source_checked_at=excluded.source_checked_at,updated_at=now();

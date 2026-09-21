-- Complete SPEDIDAM spectacle musical criteria from the official current program page.
-- Checked 2026-09-21.
insert into public.funding_criteria
(funding_program_id,criterion_key,subject_type,operator,expected_value,required,blocking,source_text,source_url,verification_status,source_checked_at)
select fp.id,v.k,v.s,v.o,v.e::jsonb,true,true,v.t,fp.official_url,'verified','2026-09-21T00:00:00Z'
from public.funding_programs fp cross join (values
('project_duration_months','project','lte','6','La période totale couverte par l’aide ne peut excéder six mois.'),
('rehearsal_min_fee','project','gte','120','Le tarif minimum de répétition est de 120 euros brut par jour.'),
('performance_min_fee','project','gte','175','Le tarif minimum de représentation est de 175 euros brut par cachet.'),
('artist_employer_cost','project','gte','6000','Le coût total employeur des artistes-interprètes doit atteindre au moins 6 000 euros.'),
('aid_share_standard','application','lte','0.4','L’aide ne peut excéder 40 % du coût total employeur hors régime grand ensemble.'),
('aid_share_large_ensemble','application','lte','0.5','Pour un ensemble d’au moins huit artistes présents sur scène à toutes les dates, l’aide ne peut excéder 50 % du coût total employeur.'),
('not_public_body','organization','eq','true','Les structures étatiques, collectivités, municipalités, communautés de communes et structures majoritairement contrôlées par une personne morale de droit public sont exclues.'),
('signed_firm_date_contract','application','eq','true','Le dossier doit comporter un contrat signé des deux parties pour une date ferme postérieure à la commission ; les courriels ne sont pas acceptés.'),
('previous_grant_balance_requested','application','eq','true','Avant un nouveau dossier, le versement du solde de l’aide précédente doit avoir été demandé.'),
('one_live_grant_per_year','application','eq','true','Une seule aide spectacle musical, spectacle dramatique/chorégraphique/cirque/marionnette ou festival peut être accordée par structure et par année civile.')
) v(k,s,o,e,t)
where fp.provider_name='SPEDIDAM' and fp.name='Aide spectacle musical'
on conflict(funding_program_id,criterion_key) do update set subject_type=excluded.subject_type,operator=excluded.operator,expected_value=excluded.expected_value,source_text=excluded.source_text,source_url=excluded.source_url,verification_status='verified',source_checked_at=excluded.source_checked_at,updated_at=now();

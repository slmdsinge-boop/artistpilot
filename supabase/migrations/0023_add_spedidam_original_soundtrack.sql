-- Add current SPEDIDAM original soundtrack aid.
-- Official program page checked 2026-09-21.
insert into public.funding_programs
(provider_name,name,description,official_url,funding_types,project_types,applicant_types,deadline_date,deadline_text,max_amount_eur,eligibility_notes,verification_status,verified_at)
select 'SPEDIDAM','Aide à la création d’une bande originale pour spectacle dramatique ou chorégraphique',
'Aide à la création et/ou l’enregistrement d’une bande originale musicale spécialement destinée à sonoriser un spectacle.',
'https://www.spedidam.fr/aides-aux-projets/nos-programmes/aide-a-la-creation-dune-bande-originale-pour-le-spectacle-dramatique-ou-choregraphique/',
ARRAY['création','enregistrement','spectacle vivant'],ARRAY['bande_originale','spectacle'],ARRAY['structure employeur'],
NULL,'Dossier complet via ADEL avant la date limite du calendrier de la commission SPEDIDAM.',NULL,
'Critères actuels vérifiés sur la page officielle SPEDIDAM.',
'verified',now()
where not exists(select 1 from public.funding_programs where provider_name='SPEDIDAM' and name='Aide à la création d’une bande originale pour spectacle dramatique ou chorégraphique');

insert into public.funding_criteria
(funding_program_id,criterion_key,subject_type,operator,expected_value,required,blocking,source_text,source_url,verification_status,source_checked_at)
select fp.id,v.k,v.s,v.o,v.e::jsonb,true,true,v.t,fp.official_url,'verified','2026-09-21T00:00:00Z'
from public.funding_programs fp cross join (values
('original_soundtrack_for_show','project','eq','true','La bande originale doit être enregistrée spécifiquement pour sonoriser le spectacle.'),
('soundtrack_min_duration_or_share','project','eq','true','La bande originale doit durer au moins 20 minutes ou représenter au moins un tiers de la durée totale du spectacle.'),
('eligible_show_type','project','eq','true','Le spectacle doit relever des catégories admises : dramatique, chorégraphique, cirque, sons et lumières, revue, cabaret, music-hall ou marionnettes.'),
('after_commission','project','eq','true','Commande musicale, répétitions et enregistrement doivent être postérieurs au dernier jour de la commission.'),
('employs_musicians','organization','eq','true','La structure doit employer directement les artistes-interprètes musiciens participant à l’enregistrement et émettre leurs bulletins de paie.'),
('rehearsal_min_fee','project','gte','120','Tarif minimum de répétition : 120 euros brut par jour.'),
('recording_min_fee','project','gte','185','Tarif minimum d’enregistrement : 185 euros brut par cachet.'),
('max_work_days','project','lte','10','L’aide porte sur un maximum de dix jours de travail, répétitions et enregistrement compris.'),
('min_recording_days','project','gte','1','Le projet doit comprendre au moins un jour d’enregistrement.'),
('not_public_body','organization','eq','true','Les structures publiques et celles majoritairement contrôlées par une personne morale de droit public sont exclues.'),
('music_commission_cap','application','lte','3000','Le montant de commande musicale pris en compte est plafonné à 3 000 euros.'),
('composer_performer_combined_cap','application','lte','3500','Si le même artiste est compositeur et interprète, commande musicale plus coût employeur de cet artiste : plafond 3 500 euros.'),
('aid_share','application','lte','0.6','L’aide ne peut excéder 60 % du coût total employeur éligible et de la commande musicale.'),
('spedidam_attendance_sheet','application','eq','true','Une feuille de présence SPEDIDAM conforme doit être signée par les artistes participant à l’enregistrement.'),
('rights_compliant_contract','application','eq','true','Les contrats d’engagement ne doivent pas prévoir de cession de droits excédant l’autorisation de fixation prévue par le dispositif.'),
('previous_same_category_paid','application','eq','true','Avant un nouveau dossier, le versement de l’aide précédente de la même catégorie doit avoir été demandé.'),
('one_soundtrack_grant_per_year','application','eq','true','Une seule aide à la création/enregistrement d’une bande originale peut être accordée par année civile.'),
('project_starts_within_six_months','project','eq','true','Le projet doit débuter au plus tard six mois après le dernier jour de la commission, sauf report autorisé.')
) v(k,s,o,e,t)
where fp.provider_name='SPEDIDAM' and fp.name='Aide à la création d’une bande originale pour spectacle dramatique ou chorégraphique'
on conflict(funding_program_id,criterion_key) do update set subject_type=excluded.subject_type,operator=excluded.operator,expected_value=excluded.expected_value,source_text=excluded.source_text,source_url=excluded.source_url,verification_status='verified',source_checked_at=excluded.source_checked_at,updated_at=now();

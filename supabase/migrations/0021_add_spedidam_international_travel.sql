-- Add current SPEDIDAM international travel aid and verified deterministic criteria.
-- Official current program page checked 2026-09-21.
insert into public.funding_programs
(provider_name,name,description,official_url,funding_types,project_types,applicant_types,deadline_date,deadline_text,max_amount_eur,eligibility_notes,verification_status,verified_at)
select 'SPEDIDAM','Aide au déplacement à l’international',
'Aide aux frais de déplacement des artistes-interprètes pour le spectacle vivant hors de France, incluant certains trajets DROM-COM/métropole.',
'https://www.spedidam.fr/aides-aux-projets/nos-programmes/aide-au-deplacement-a-linternational/',
ARRAY['tournée','déplacement','international'],ARRAY['tournee','spectacle'],ARRAY['structure employeur'],
NULL,'Dossier complet avant la date limite du calendrier de la commission SPEDIDAM.',NULL,
'Critères actuels vérifiés sur la page officielle. Le montant dépend de la destination et du nombre d’artistes.',
'verified',now()
where not exists(select 1 from public.funding_programs where provider_name='SPEDIDAM' and name='Aide au déplacement à l’international');

insert into public.funding_criteria
(funding_program_id,criterion_key,subject_type,operator,expected_value,required,blocking,source_text,source_url,verification_status,source_checked_at)
select fp.id,v.k,v.s,v.o,v.e::jsonb,true,true,v.t,fp.official_url,'verified','2026-09-21T00:00:00Z'
from public.funding_programs fp cross join (values
('international_live_travel','project','eq','true','Le déplacement concerne des artistes-interprètes dans le cadre du spectacle vivant hors de France, ou un déplacement éligible entre DROM-COM et métropole.'),
('after_commission','project','eq','true','Le déplacement doit avoir lieu après le dernier jour de la commission.'),
('employs_travelling_artists','organization','eq','true','La structure doit être l’employeur des artistes-interprètes concernés et émettre leurs bulletins de paie.'),
('min_performance_days','project','gte','3','Les artistes-interprètes doivent se produire lors d’au moins trois jours de représentations.'),
('musician_min_fee','project','gte','175','Cachet brut minimum de représentation : 175 euros pour musicien, chanteur ou choriste.'),
('other_performer_min_fee','project','gte','130','Cachet brut minimum de représentation : 130 euros pour comédien, danseur ou circassien.'),
('music_component','project','eq','true','Le spectacle doit comporter au moins un musicien sur scène ou une bande originale musicale éligible d’au moins 20 minutes ou un tiers de sa durée.'),
('not_public_body','organization','eq','true','Les structures publiques et celles majoritairement contrôlées par une personne morale de droit public sont exclues.'),
('single_continuous_trip','project','eq','true','La demande doit porter sur un seul déplacement continu ; le retour en métropole marque la fin du déplacement.'),
('tickets_paid_by_structure','organization','eq','true','Billets ou location de véhicule doivent être achetés/payés par la structure et facturés à son nom.'),
('standard_aid_share','application','lte','0.65','L’aide ne peut excéder 65 % des frais de déplacement éligibles justifiés.'),
('drom_metropole_aid_share','application','lte','0.8','Pour une tournée en métropole au départ des DROM-COM, le plafond est porté à 80 %.'),
('europe_cap_per_artist','application','lte','750','Pour l’Europe, plafond de 750 euros par artiste-interprète.'),
('world_cap_per_artist','application','lte','1500','Pour le reste du monde, plafond de 1 500 euros par artiste-interprète.'),
('max_supported_artists','project','lte','15','Les plafonds par personne s’appliquent à 15 artistes-interprètes au maximum.'),
('three_signed_invitations','application','eq','true','Trois lettres d’invitation signées provenant d’au moins trois lieux différents et précisant au moins trois dates doivent être fournies.'),
('travel_quote','application','eq','true','Un devis/facture d’agence de voyages au nom de la structure ou une capture d’un site de voyages en ligne doit être fournie.'),
('max_two_travel_grants_year','application','eq','true','Deux aides au déplacement au maximum peuvent être accordées par structure et par année civile.'),
('oldest_unsold_grant_handled','application','eq','true','Si deux aides au déplacement ne sont pas soldées, le versement du dossier le plus ancien doit être demandé avant un nouveau dépôt.'),
('trip_within_six_months','project','eq','true','Le déplacement doit avoir lieu au plus tard six mois après la commission, sauf autorisation de report.')
) v(k,s,o,e,t)
where fp.provider_name='SPEDIDAM' and fp.name='Aide au déplacement à l’international'
on conflict(funding_program_id,criterion_key) do update set subject_type=excluded.subject_type,operator=excluded.operator,expected_value=excluded.expected_value,source_text=excluded.source_text,source_url=excluded.source_url,verification_status='verified',source_checked_at=excluded.source_checked_at,updated_at=now();

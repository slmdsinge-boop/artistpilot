-- New SPEDIDAM program launched September 2026.
-- Official program page checked 2026-09-21.
insert into public.funding_programs
(provider_name,name,description,official_url,funding_types,project_types,applicant_types,deadline_date,deadline_text,max_amount_eur,eligibility_notes,verification_status,verified_at)
select
'SPEDIDAM',
'Aide à la programmation musicale dans les lieux pluridisciplinaires',
'Soutien à la diffusion d’un grand ensemble musical ou spectacle musical par un réseau de scènes pluridisciplinaires.',
'https://www.spedidam.fr/aides-aux-projets/nos-programmes/diffusion-du-spectacle-vivant-aide-a-la-programmation-musicale-dans-les-lieux-pluridisciplinaires/',
ARRAY['diffusion','spectacle vivant'],ARRAY['spectacle','tournee'],ARRAY['scène pluridisciplinaire'],
NULL,'Deux commissions : décembre et mars. Le dossier concerne la saison suivant la commission ; date limite selon calendrier SPEDIDAM.',NULL,
'Nouveau programme lancé en septembre 2026. Critères déterministes structurés séparément.',
'verified',now()
where not exists(select 1 from public.funding_programs where provider_name='SPEDIDAM' and name='Aide à la programmation musicale dans les lieux pluridisciplinaires');

insert into public.funding_criteria
(funding_program_id,criterion_key,subject_type,operator,expected_value,required,blocking,source_text,source_url,verification_status,source_checked_at)
select fp.id,v.k,v.s,v.o,v.e::jsonb,true,true,v.t,fp.official_url,'verified','2026-09-21T00:00:00Z'
from public.funding_programs fp cross join (values
('multidisciplinary_scene','organization','eq','true','La structure porteuse doit être une scène pluridisciplinaire.'),
('not_festival','organization','eq','true','La demande ne peut pas être portée par un festival.'),
('venue_count','project','gte','4','La diffusion doit associer au moins quatre salles pluridisciplinaires distinctes.'),
('venue_count_max','project','lte','6','La diffusion est limitée à six salles pluridisciplinaires distinctes.'),
('venue_min_capacity','project','gte','300','Chaque salle doit avoir une jauge minimale de 300 places.'),
('onstage_artist_count','project','gte','8','Le spectacle doit comprendre au moins huit artistes au plateau.'),
('musician_share','project','gte','0.5','Au moins 50 % des artistes au plateau doivent être musiciens, chanteurs ou instrumentistes.'),
('musician_min_fee','project','gte','175','Le cachet brut minimum de représentation est de 175 euros pour les musiciens, chanteurs et choristes.'),
('other_performer_min_fee','project','gte','130','Le cachet brut minimum de représentation est de 130 euros pour les comédiens, danseurs et circassiens.'),
('next_season_programming','project','eq','true','Les dates doivent être programmées pendant la saison suivant le passage en commission.'),
('partner_commitment_letters','application','eq','true','Des lettres d’engagement signées de toutes les structures doivent être fournies.'),
('multipartite_agreement','application','eq','true','Une convention multipartite de partenariat avec les structures partenaires doit être fournie.'),
('previous_same_category_paid','application','eq','true','Avant un nouveau dossier, le versement de l’aide du précédent dossier de la même catégorie doit avoir été demandé.')
) v(k,s,o,e,t)
where fp.provider_name='SPEDIDAM' and fp.name='Aide à la programmation musicale dans les lieux pluridisciplinaires'
on conflict(funding_program_id,criterion_key) do update set subject_type=excluded.subject_type,operator=excluded.operator,expected_value=excluded.expected_value,source_text=excluded.source_text,source_url=excluded.source_url,verification_status='verified',source_checked_at=excluded.source_checked_at,updated_at=now();

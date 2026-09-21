-- Verified CNM criteria: music video and live production/diffusion.
-- Official CNM sources checked 2026-09-21.

insert into public.funding_criteria
(funding_program_id,criterion_key,subject_type,operator,expected_value,required,blocking,source_text,source_url,verification_status,source_checked_at)
select fp.id,v.k,v.s,v.o,v.e::jsonb,true,true,v.t,
'https://cnm.fr/aides-financieres/aide-a-la-production-de-musique-en-images/','verified','2026-09-21T00:00:00Z'
from public.funding_programs fp cross join (values
('cnm_affiliated','organization','eq','true','La structure doit être affiliée au CNM.'),
('legal_person_or_sole_trader','organization','eq','true','Le demandeur doit être une personne morale ou un entrepreneur individuel.'),
('main_activity_recording_or_publishing','organization','eq','true','L’activité principale doit être l’enregistrement sonore ou l’édition musicale.'),
('employs_artists','organization','eq','true','La structure doit être employeuse des artistes.'),
('majority_audiovisual_costs','organization','eq','true','La structure doit prendre en charge la majorité des coûts de production audiovisuelle.'),
('release_min_tracks_or_duration','project','eq','true','L’actualité discographique liée doit comprendre au moins cinq phonogrammes ou plus de vingt minutes cumulées.'),
('commercial_distribution','project','eq','true','L’actualité discographique doit bénéficier d’une distribution commerciale conforme au dispositif.'),
('not_compilation_or_multiartist','project','eq','true','Le titre ne doit pas provenir d’une compilation ou d’un album multi-artistes.'),
('own_resources_share','project','gt','0.15','Le projet doit être financé à plus de 15 % par des ressources propres hors aides des organismes de gestion collective.'),
('not_broadcast_before_deadline','project','eq','true','La vidéomusique ne doit pas être diffusée avant la date limite de dépôt.'),
('not_concert_capture','project','eq','true','Les captations de concert, y compris scénarisées, ne sont pas éligibles.')
) v(k,s,o,e,t)
where fp.provider_name='CNM' and fp.name='Aide à la production de musique en images'
on conflict(funding_program_id,criterion_key) do update set subject_type=excluded.subject_type,operator=excluded.operator,expected_value=excluded.expected_value,source_text=excluded.source_text,source_url=excluded.source_url,verification_status='verified',source_checked_at=excluded.source_checked_at,updated_at=now();

insert into public.funding_criteria
(funding_program_id,criterion_key,subject_type,operator,expected_value,required,blocking,source_text,source_url,verification_status,source_checked_at)
select fp.id,v.k,v.s,v.o,v.e::jsonb,true,true,v.t,
'https://cnm.fr/aides-financieres/aide-a-la-production-et-a-la-diffusion-de-spectacle-vivant/','verified','2026-09-21T00:00:00Z'
from public.funding_programs fp cross join (values
('cnm_affiliated','organization','eq','true','La structure doit être affiliée au CNM.'),
('live_production_entity','organization','eq','true','Le demandeur doit être une entité de production de spectacle vivant dans le champ du CNM.'),
('spectacle_licence_2','organization','eq','true','La structure doit être titulaire de la licence 2.'),
('producer_generator','organization','eq','true','La structure doit être le producteur générateur du projet.'),
('employs_artistic_team','organization','eq','true','La structure doit pouvoir justifier de l’emploi du plateau artistique.'),
('organization_age_years','organization','gte','1','La structure doit justifier d’au moins une année d’activité.'),
('cnm_field','project','eq','true','Le projet doit relever du champ du CNM.'),
('confirmed_performances_tax_field','project','gte','8','Dans le champ de perception de la taxe, au moins huit représentations doivent être fermement confirmées par écrit sur 24 mois maximum.'),
('max_free_performance_share','project','lte','0.3333333333','Au maximum un tiers des représentations peuvent être sans billetterie payante.')
) v(k,s,o,e,t)
where fp.provider_name='CNM' and fp.name='Aide à la production et à la diffusion de spectacle vivant'
on conflict(funding_program_id,criterion_key) do update set subject_type=excluded.subject_type,operator=excluded.operator,expected_value=excluded.expected_value,source_text=excluded.source_text,source_url=excluded.source_url,verification_status='verified',source_checked_at=excluded.source_checked_at,updated_at=now();

-- Add current SPEDIDAM promotion-by-image program and deterministic criteria.
-- Official program page checked 2026-09-21.
insert into public.funding_programs
(provider_name,name,description,official_url,funding_types,project_types,applicant_types,deadline_date,deadline_text,max_amount_eur,eligibility_notes,verification_status,verified_at)
select 'SPEDIDAM','Aide à la promotion par l’image',
'Aide à la réalisation d’une vidéo promotionnelle destinée à promouvoir un artiste-interprète ou un groupe.',
'https://www.spedidam.fr/aides-aux-projets/nos-programmes/aide-a-la-promotion-par-limage/',
ARRAY['promotion','audiovisuel'],ARRAY['video_promotionnelle'],ARRAY['structure porteuse'],
NULL,'Dépôt complet avant la date limite du calendrier de la commission SPEDIDAM.',2500,
'Ne finance pas un clip artistique, un documentaire, un spectacle ou un titre reproduit intégralement.',
'verified',now()
where not exists(select 1 from public.funding_programs where provider_name='SPEDIDAM' and name='Aide à la promotion par l’image');

insert into public.funding_criteria
(funding_program_id,criterion_key,subject_type,operator,expected_value,required,blocking,source_text,source_url,verification_status,source_checked_at)
select fp.id,v.k,v.s,v.o,v.e::jsonb,true,true,v.t,fp.official_url,'verified','2026-09-21T00:00:00Z'
from public.funding_programs fp cross join (values
('promotional_video','project','eq','true','Le projet doit être une vidéo promotionnelle destinée à promouvoir un artiste-interprète ou un groupe.'),
('not_documentary_full_show_or_track','project','eq','true','Documentaires, spectacles et titres reproduits intégralement sont exclus.'),
('professional_video_provider','organization','eq','true','La réalisation doit être confiée à une structure professionnelle immatriculée au répertoire des entreprises.'),
('project_after_commission','project','eq','true','La réalisation, enregistrement inclus, doit être postérieure au dernier jour de la commission.'),
('not_public_body','organization','eq','true','Les structures publiques et celles majoritairement contrôlées par une personne morale de droit public sont exclues.'),
('aid_amount','application','lte','2500','Le montant de l’aide est plafonné à 2 500 euros.'),
('aid_share','application','lte','0.8','L’aide ne peut excéder 80 % des frais de réalisation.'),
('prior_grant_payment_requested','application','eq','true','Avant un nouveau dossier, le versement de toute aide précédente doit avoir été demandé.'),
('one_image_promo_grant_per_year','application','eq','true','Une seule aide de ce programme peut être accordée par structure et par année civile.'),
('completed_within_six_months','project','eq','true','La vidéo doit être réalisée dans les six mois suivant le dernier jour de la commission.'),
('public_within_three_months','project','eq','true','La vidéo doit être mise à disposition du public au plus tard trois mois après sa réalisation.')
) v(k,s,o,e,t)
where fp.provider_name='SPEDIDAM' and fp.name='Aide à la promotion par l’image'
on conflict(funding_program_id,criterion_key) do update set subject_type=excluded.subject_type,operator=excluded.operator,expected_value=excluded.expected_value,source_text=excluded.source_text,source_url=excluded.source_url,verification_status='verified',source_checked_at=excluded.source_checked_at,updated_at=now();

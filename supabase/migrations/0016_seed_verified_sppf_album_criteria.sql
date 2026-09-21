-- SPPF album creation criteria verified against official 2026 SPPF pages/PDF.
-- Checked 2026-09-21.
insert into public.funding_criteria
(funding_program_id,criterion_key,subject_type,operator,expected_value,required,blocking,source_text,source_url,verification_status,source_checked_at)
select fp.id,v.k,v.s,v.o,v.e::jsonb,true,true,v.t,
'https://www.sppf.com/wp-content/uploads/2026/02/Fiche-pratique-album.pdf',
'verified','2026-09-21T00:00:00Z'
from public.funding_programs fp cross join (values
('project_producer','organization','eq','true','Le demandeur doit être le producteur du projet.'),
('legal_structure','organization','eq','true','Le projet doit être produit via une structure juridique ou une association légalement constituée.'),
('sppf_link','organization','eq','true','Le demandeur doit être associé SPPF, en licence exclusive avec un associé SPPF ou avoir confié un mandat de gestion à un associé SPPF.'),
('prior_commercial_album','organization','eq','true','Le label doit avoir déjà produit au moins un album distribué commercialement selon les conditions du dispositif.'),
('employs_artists','organization','eq','true','Le producteur doit être entièrement ou en partie employeur des artistes et satisfaire aux obligations sociales prévues.'),
('collective_agreement_compliance','organization','eq','true','Le producteur doit respecter la convention collective applicable et les minima en vigueur.'),
('national_physical_distribution','project','eq','true','Un contrat de distribution physique national du catalogue ou nominatif pour le projet doit être fourni.'),
('min_unreleased_tracks','project','gte','3','L’EP ou l’album doit comporter au moins trois titres inédits.'),
('excluded_live_remix_compilation','project','eq','false','Les live, remixes et compilations sont exclus.'),
('application_before_release','application','eq','true','Le dossier doit être présenté en commission avant la commercialisation physique et/ou numérique.'),
('producer_own_contribution_share','project','gte','0.5','L’apport du producteur doit représenter au moins 50 % du cadre subventionnable et provenir de ses fonds propres.'),
('sppf_request_share','application','lte','0.4','L’aide sollicitée auprès de la SPPF ne peut excéder 40 % du cadre subventionnable.'),
('eligible_fixation_cost_share','project','gte','0.5','Au moins 50 % des coûts de fixation doivent être engagés dans les territoires admis par le dispositif.')
) v(k,s,o,e,t)
where fp.provider_name='SPPF' and fp.name='Aide à la création'
on conflict(funding_program_id,criterion_key) do update set
subject_type=excluded.subject_type,operator=excluded.operator,expected_value=excluded.expected_value,
source_text=excluded.source_text,source_url=excluded.source_url,verification_status='verified',
source_checked_at=excluded.source_checked_at,updated_at=now();

update public.funding_programs
set deadline_date='2026-10-07',
deadline_text='Commission Aide à la création du 4 novembre 2026 — date limite de dépôt : 7 octobre 2026. Une commission suivante est annoncée le 17 décembre 2026, dépôt avant le 19 novembre.',
verification_status='verified', verified_at=now()
where provider_name='SPPF' and name='Aide à la création';

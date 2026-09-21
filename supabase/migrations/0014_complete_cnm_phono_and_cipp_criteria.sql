-- Complete verified CNM phonographic criteria and seed CIPP criteria.
-- Official CNM sources checked 2026-09-21.

insert into public.funding_criteria
(funding_program_id,criterion_key,subject_type,operator,expected_value,required,blocking,source_text,source_url,verification_status,source_checked_at)
select fp.id,v.k,v.s,v.o,v.e::jsonb,true,true,v.t,
'https://cnm.fr/aides-financieres/aide-a-la-production-phonographique-3/','verified','2026-09-21T00:00:00Z'
from public.funding_programs fp cross join (values
('catalog_min_reference','organization','eq','true','Le catalogue doit comprendre au moins une référence de cinq phonogrammes et/ou plus de vingt minutes, avec distribution commerciale professionnelle.'),
('economic_threshold','organization','eq','true','Le demandeur doit satisfaire au moins un des seuils économiques alternatifs prévus par le dispositif.'),
('previous_album_sales_limit','project','eq','true','Hors premier album, le précédent album de l’artiste ne doit pas dépasser 50 000 exemplaires physiques ou équivalent streams.')
) v(k,s,o,e,t)
where fp.provider_name='CNM' and fp.name='Aide à la production phonographique'
on conflict(funding_program_id,criterion_key) do update set subject_type=excluded.subject_type,operator=excluded.operator,expected_value=excluded.expected_value,source_text=excluded.source_text,source_url=excluded.source_url,verification_status='verified',source_checked_at=excluded.source_checked_at,updated_at=now();

insert into public.funding_criteria
(funding_program_id,criterion_key,subject_type,operator,expected_value,required,blocking,source_text,source_url,verification_status,source_checked_at)
select fp.id,v.k,v.s,v.o,v.e::jsonb,true,true,v.t,
'https://cnm.fr/aides-financieres/credit-dimpot-en-faveur-de-la-production-phonographique/','verified','2026-09-21T00:00:00Z'
from public.funding_programs fp cross join (values
('corporate_tax_subject','organization','eq','true','Le CIPP bénéficie aux entreprises soumises à l’impôt sur les sociétés.'),
('eea_or_french_with_french_establishment','organization','eq','true','L’entreprise doit être française ou ressortissante de l’EEE avec un établissement stable en France.'),
('phonogram_producer','organization','eq','true','Le dispositif est réservé aux entreprises de production phonographique.'),
('eligible_expenses_in_eea','project','eq','true','Les dépenses ouvrant droit au crédit doivent être effectuées dans un État membre de l’EEE.'),
('requires_provisional_and_final_approval','application','eq','true','Les critères sont contrôlés via un agrément provisoire puis un agrément définitif.')
) v(k,s,o,e,t)
where fp.provider_name='CNM' and (fp.name ilike '%CIPP%' or fp.name ilike '%crédit d%impôt%production phonographique%')
on conflict(funding_program_id,criterion_key) do update set subject_type=excluded.subject_type,operator=excluded.operator,expected_value=excluded.expected_value,source_text=excluded.source_text,source_url=excluded.source_url,verification_status='verified',source_checked_at=excluded.source_checked_at,updated_at=now();

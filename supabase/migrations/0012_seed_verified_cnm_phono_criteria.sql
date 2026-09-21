-- Seed only deterministic criteria checked against the official CNM page.
-- Source checked: 2026-09-21.
-- Program: Aide à la production phonographique.
insert into public.funding_criteria
(funding_program_id, criterion_key, subject_type, operator, expected_value, required, blocking, source_text, source_url, verification_status, source_checked_at)
select fp.id, v.criterion_key, v.subject_type, v.operator, v.expected_value::jsonb, true, true, v.source_text,
'https://cnm.fr/aides-financieres/aide-a-la-production-phonographique-3/', 'verified', '2026-09-21T00:00:00Z'
from public.funding_programs fp
cross join (values
 ('cnm_affiliated','organization','eq','true','La structure demandeuse doit être affiliée au CNM.'),
 ('legal_person','organization','eq','true','La structure demandeuse doit être une personne morale.'),
 ('employs_artists','organization','eq','true','La structure demandeuse doit être l’entité employeuse des artistes.'),
 ('organization_age_years','organization','gte','1','La structure doit disposer d’au moins une année d’existence à la date du dépôt.'),
 ('owns_masters','organization','eq','true','La structure doit détenir les droits sur les phonogrammes objets de la demande.'),
 ('project_min_tracks_or_duration','project','eq','true','Le projet doit comporter au moins cinq phonogrammes musicaux ou dépasser vingt minutes de durée cumulée.'),
 ('commercial_distribution','project','eq','true','Le projet doit bénéficier d’une distribution commerciale conforme au dispositif.'),
 ('own_resources_share','project','gt','0.15','Le projet doit être financé à plus de 15 % par des ressources propres, hors aides des organismes de gestion collective.'),
 ('not_compilation','project','eq','true','Le projet ne doit pas être une compilation, sous réserve de l’exception prévue pour certains répertoires classiques et contemporains.'),
 ('uncommercialized_master_share','project','gte','0.5','Au moins 50 % des phonogrammes doivent avoir un master non encore commercialisé.')
) as v(criterion_key,subject_type,operator,expected_value,source_text)
where fp.provider_name='CNM' and fp.name='Aide à la production phonographique'
on conflict (funding_program_id,criterion_key) do update set
 subject_type=excluded.subject_type, operator=excluded.operator, expected_value=excluded.expected_value,
 required=excluded.required, blocking=excluded.blocking, source_text=excluded.source_text,
 source_url=excluded.source_url, verification_status=excluded.verification_status,
 source_checked_at=excluded.source_checked_at, updated_at=now();

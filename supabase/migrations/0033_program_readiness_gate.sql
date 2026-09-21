-- V2.4 safety gate: a program cannot be presented as deterministically compatible
-- unless it has verified eligibility criteria and sufficiently explicit project applicability.
create or replace function public.funding_program_readiness(target_artist uuid,target_project uuid)
returns table(funding_program_id uuid,readiness_status text,reason text)
language sql stable security invoker set search_path=public as $$
with t as (
 select p.project_type from public.projects p where p.id=target_project and p.artist_id=target_artist
), programs as (
 select fp.id,fp.verification_status,fp.project_types,
 count(fc.id) filter(where fc.verification_status='verified' and fc.criterion_kind='eligibility') verified_eligibility_count,
 count(fc.id) filter(where fc.verification_status='to_verify') unverified_criteria_count
 from public.funding_programs fp
 left join public.funding_criteria fc on fc.funding_program_id=fp.id
 group by fp.id
)
select p.id,
 case
  when p.verification_status<>'verified' then 'to_verify'
  when p.verified_eligibility_count=0 then 'insufficient_rules'
  when p.unverified_criteria_count>0 then 'partial_verification'
  when p.project_types is null or cardinality(p.project_types)=0 then 'broad_applicability'
  when exists(select 1 from t where project_type=any(p.project_types)) then 'ready'
  else 'not_applicable'
 end,
 case
  when p.verification_status<>'verified' then 'Programme non vérifié.'
  when p.verified_eligibility_count=0 then 'Aucun critère d’éligibilité vérifié exploitable.'
  when p.unverified_criteria_count>0 then 'Certains critères restent à vérifier.'
  when p.project_types is null or cardinality(p.project_types)=0 then 'Applicabilité projet trop large : vérification manuelle recommandée.'
  when exists(select 1 from t where project_type=any(p.project_types)) then 'Règles vérifiées et type de projet explicitement compatible.'
  else 'Type de projet non couvert.'
 end
from programs p;
$$;
grant execute on function public.funding_program_readiness(uuid,uuid) to authenticated;
comment on function public.funding_program_readiness(uuid,uuid) is 'Safety/readiness classification. Only ready should support a strong deterministic compatibility display.';

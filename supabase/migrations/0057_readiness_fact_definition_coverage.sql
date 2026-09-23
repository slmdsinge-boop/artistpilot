-- Readiness V3: a strong deterministic eligibility result also requires every
-- verified blocking eligibility criterion to have a canonical fact definition
-- with the same subject type. Missing metadata means "not ready", never "not eligible".

create or replace function public.funding_program_readiness(target_artist uuid,target_project uuid)
returns table(funding_program_id uuid,readiness_status text,reason text)
language sql stable security invoker set search_path=public as $$
with t as (
 select p.project_type from public.projects p
 where p.id=target_project and p.artist_id=target_artist
), programs as (
 select fp.id,fp.verification_status,fp.project_types,
 count(fc.id) filter(
   where fc.verification_status='verified'
     and fc.criterion_kind='eligibility'
 ) verified_eligibility_count,
 count(fc.id) filter(where fc.verification_status='to_verify') unverified_criteria_count,
 count(fc.id) filter(
   where fc.verification_status='verified'
     and fc.criterion_kind='eligibility'
     and fc.blocking
     and not exists (
       select 1
       from public.fact_definitions fd
       where fd.fact_key=fc.criterion_key
         and fd.subject_type=fc.subject_type
     )
 ) missing_fact_definition_count
 from public.funding_programs fp
 left join public.funding_criteria fc on fc.funding_program_id=fp.id
 group by fp.id
), freshness as (
 select p.id,(public.funding_program_source_freshness(p.id)).*
 from programs p
)
select p.id,
 case
  when p.verification_status<>'verified' then 'to_verify'
  when f.freshness_status='stale' then 'stale_sources'
  when f.freshness_status='unknown' then 'source_date_unknown'
  when p.verified_eligibility_count=0 then 'insufficient_rules'
  when p.unverified_criteria_count>0 then 'partial_verification'
  when p.missing_fact_definition_count>0 then 'incomplete_fact_definitions'
  when p.project_types is null or cardinality(p.project_types)=0 then 'broad_applicability'
  when exists(select 1 from t where project_type=any(p.project_types)) then 'ready'
  else 'not_applicable'
 end,
 case
  when p.verification_status<>'verified' then 'Programme non vérifié.'
  when f.freshness_status='stale' then 'Une ou plusieurs sources officielles doivent être revérifiées.'
  when f.freshness_status='unknown' then 'La date de dernière vérification de certaines sources est inconnue.'
  when p.verified_eligibility_count=0 then 'Aucun critère d’éligibilité vérifié exploitable.'
  when p.unverified_criteria_count>0 then 'Certains critères restent à vérifier.'
  when p.missing_fact_definition_count>0 then
    p.missing_fact_definition_count::text || ' critère(s) d’éligibilité bloquant(s) restent à formaliser avant une analyse déterministe.'
  when p.project_types is null or cardinality(p.project_types)=0 then 'Applicabilité projet trop large : vérification manuelle recommandée.'
  when exists(select 1 from t where project_type=any(p.project_types)) then 'Règles, sources et définitions de faits suffisamment vérifiées.'
  else 'Type de projet non couvert.'
 end
from programs p
join freshness f on f.id=p.id;
$$;

grant execute on function public.funding_program_readiness(uuid,uuid) to authenticated;

comment on function public.funding_program_readiness(uuid,uuid) is
'Safety/readiness classification. Ready requires fresh verified rules, explicit project applicability and canonical fact definitions for every verified blocking eligibility criterion.';

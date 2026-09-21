-- Source freshness: verified rules are not trusted forever.
alter table public.funding_programs add column if not exists source_checked_at timestamptz;
alter table public.funding_programs add column if not exists recheck_after interval not null default interval '180 days';
alter table public.funding_criteria add column if not exists recheck_after interval not null default interval '180 days';

-- Preserve existing verification timestamps when available; otherwise do not invent a check date.
update public.funding_programs
set source_checked_at=coalesce(source_checked_at,verified_at)
where verification_status='verified' and source_checked_at is null and verified_at is not null;

create or replace function public.funding_program_source_freshness(target_program uuid)
returns table(freshness_status text,oldest_check timestamptz,stale_count bigint,unknown_count bigint)
language sql stable security invoker set search_path=public as $$
with rows as (
 select
  case
   when fc.source_checked_at is null then 'unknown'
   when now() > fc.source_checked_at + fc.recheck_after then 'stale'
   else 'fresh'
  end status,
  fc.source_checked_at
 from public.funding_criteria fc
 where fc.funding_program_id=target_program and fc.verification_status='verified'
)
select
 case
  when count(*) filter(where status='stale')>0 then 'stale'
  when count(*) filter(where status='unknown')>0 then 'unknown'
  when count(*)=0 then 'unknown'
  else 'fresh' end,
 min(source_checked_at),
 count(*) filter(where status='stale'),
 count(*) filter(where status='unknown')
from rows;
$$;
grant execute on function public.funding_program_source_freshness(uuid) to authenticated;

-- Readiness V2: freshness is a prerequisite for a strong deterministic result.
create or replace function public.funding_program_readiness(target_artist uuid,target_project uuid)
returns table(funding_program_id uuid,readiness_status text,reason text)
language sql stable security invoker set search_path=public as $$
with t as (
 select p.project_type from public.projects p where p.id=target_project and p.artist_id=target_artist
), programs as (
 select fp.id,fp.verification_status,fp.project_types,
 count(fc.id) filter(where fc.verification_status='verified' and fc.criterion_kind='eligibility') verified_eligibility_count,
 count(fc.id) filter(where fc.verification_status='to_verify') unverified_criteria_count
 from public.funding_programs fp left join public.funding_criteria fc on fc.funding_program_id=fp.id group by fp.id
), freshness as (
 select p.id,(public.funding_program_source_freshness(p.id)).* from programs p
)
select p.id,
 case
  when p.verification_status<>'verified' then 'to_verify'
  when f.freshness_status='stale' then 'stale_sources'
  when f.freshness_status='unknown' then 'source_date_unknown'
  when p.verified_eligibility_count=0 then 'insufficient_rules'
  when p.unverified_criteria_count>0 then 'partial_verification'
  when p.project_types is null or cardinality(p.project_types)=0 then 'broad_applicability'
  when exists(select 1 from t where project_type=any(p.project_types)) then 'ready'
  else 'not_applicable' end,
 case
  when p.verification_status<>'verified' then 'Programme non vérifié.'
  when f.freshness_status='stale' then 'Une ou plusieurs sources officielles doivent être revérifiées.'
  when f.freshness_status='unknown' then 'La date de dernière vérification de certaines sources est inconnue.'
  when p.verified_eligibility_count=0 then 'Aucun critère d’éligibilité vérifié exploitable.'
  when p.unverified_criteria_count>0 then 'Certains critères restent à vérifier.'
  when p.project_types is null or cardinality(p.project_types)=0 then 'Applicabilité projet trop large : vérification manuelle recommandée.'
  when exists(select 1 from t where project_type=any(p.project_types)) then 'Règles et sources suffisamment vérifiées.'
  else 'Type de projet non couvert.' end
from programs p join freshness f on f.id=p.id;
$$;

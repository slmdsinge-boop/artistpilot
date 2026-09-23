-- Keep the verification queue aligned with readiness V3.
-- Missing canonical fact definitions are actionable verification work and must not
-- fall through to the generic priority 99 bucket.

create or replace function public.funding_verification_queue(target_artist uuid,target_project uuid)
returns table(
 funding_program_id uuid,provider_name text,program_name text,readiness_status text,reason text,
 official_url text,priority integer
)
language sql stable security invoker set search_path=public as $$
with r as (
 select * from public.funding_program_readiness(target_artist,target_project)
)
select fp.id,fp.provider_name,fp.name,r.readiness_status,r.reason,fp.official_url,
 case r.readiness_status
  when 'stale_sources' then 1
  when 'source_date_unknown' then 2
  when 'partial_verification' then 3
  when 'incomplete_fact_definitions' then 4
  when 'insufficient_rules' then 5
  when 'broad_applicability' then 6
  when 'to_verify' then 7
  else 99 end priority
from r join public.funding_programs fp on fp.id=r.funding_program_id
where r.readiness_status not in ('ready','not_applicable')
order by priority,fp.provider_name,fp.name;
$$;

grant execute on function public.funding_verification_queue(uuid,uuid) to authenticated;

comment on function public.funding_verification_queue(uuid,uuid) is
'Prioritized human/agent re-verification work, including missing canonical fact definitions. Does not auto-verify or invent source dates.';

-- Eligibility engine V2.2: respect blocking, criterion kind and simple conditional branches.
create or replace function public.evaluate_funding_eligibility_v22(
 target_artist uuid,target_project uuid,target_organization uuid default null
)
returns table(
 funding_program_id uuid,provider_name text,program_name text,criterion_key text,
 criterion_subject_type text,criterion_status text,actual_value jsonb,expected_value jsonb,
 operator text,source_text text,source_url text,blocking boolean,criterion_kind text
)
language sql stable security invoker set search_path=public as $$
with criteria as (
 select fc.*,fp.provider_name,fp.name program_name
 from public.funding_criteria fc join public.funding_programs fp on fp.id=fc.funding_program_id
 where fc.verification_status='verified' and fp.verification_status='verified'
), facts as (
 select ef.* from public.entity_facts ef where ef.artist_id=target_artist and (
  (ef.subject_type='project' and ef.subject_id=target_project)
  or (target_organization is not null and ef.subject_type='organization' and ef.subject_id=target_organization)
  or (ef.subject_type='artist' and ef.subject_id=target_artist)
 )
), matched as (
 select c.*,f.value actual_value,
 cf.value condition_actual
 from criteria c
 left join facts f on f.fact_key=c.criterion_key and f.subject_type=c.subject_type
 left join facts cf on c.applies_when is not null
   and cf.fact_key=c.applies_when->>'fact_key'
   and cf.subject_type=c.applies_when->>'subject_type'
), evaluated as (
 select m.*,
 case
  when applies_when is not null and condition_actual is null then 'pending_context'
  when applies_when is not null and coalesce(applies_when->>'operator','eq')='eq'
    and condition_actual is distinct from (applies_when->'value') then 'not_applicable'
  when actual_value is null then 'missing_information'
  when operator='not_null' then 'satisfied'
  when operator='eq' and actual_value=expected_value then 'satisfied'
  when operator='neq' and actual_value<>expected_value then 'satisfied'
  when operator='gte' and jsonb_typeof(actual_value)='number' and jsonb_typeof(expected_value)='number' and (actual_value#>>'{}')::numeric >= (expected_value#>>'{}')::numeric then 'satisfied'
  when operator='lte' and jsonb_typeof(actual_value)='number' and jsonb_typeof(expected_value)='number' and (actual_value#>>'{}')::numeric <= (expected_value#>>'{}')::numeric then 'satisfied'
  when operator='gt' and jsonb_typeof(actual_value)='number' and jsonb_typeof(expected_value)='number' and (actual_value#>>'{}')::numeric > (expected_value#>>'{}')::numeric then 'satisfied'
  when operator='lt' and jsonb_typeof(actual_value)='number' and jsonb_typeof(expected_value)='number' and (actual_value#>>'{}')::numeric < (expected_value#>>'{}')::numeric then 'satisfied'
  when operator='in' and jsonb_typeof(expected_value)='array' and expected_value @> jsonb_build_array(actual_value) then 'satisfied'
  else 'criterion_not_met' end status
 from matched m
)
select funding_program_id,provider_name,program_name,criterion_key,subject_type,status,
 actual_value,expected_value,operator,source_text,source_url,blocking,criterion_kind
from evaluated;
$$;
grant execute on function public.evaluate_funding_eligibility_v22(uuid,uuid,uuid) to authenticated;

create or replace function public.funding_eligibility_summary_v22(
 target_artist uuid,target_project uuid,target_organization uuid default null
)
returns table(funding_program_id uuid,provider_name text,program_name text,eligibility_status text,
 satisfied_count bigint,missing_count bigint,not_met_count bigint,pending_context_count bigint,total_count bigint)
language sql stable security invoker set search_path=public as $$
select e.funding_program_id,e.provider_name,e.program_name,
 case
  when count(*) filter(where e.criterion_status='criterion_not_met' and e.blocking and e.criterion_kind='eligibility')>0 then 'criterion_not_met'
  when count(*) filter(where e.criterion_status in('missing_information','pending_context') and e.blocking and e.criterion_kind='eligibility')>0 then 'missing_information'
  else 'potentially_compatible' end,
 count(*) filter(where e.criterion_status='satisfied'),
 count(*) filter(where e.criterion_status='missing_information' and e.blocking and e.criterion_kind='eligibility'),
 count(*) filter(where e.criterion_status='criterion_not_met' and e.blocking and e.criterion_kind='eligibility'),
 count(*) filter(where e.criterion_status='pending_context' and e.blocking and e.criterion_kind='eligibility'),
 count(*) filter(where e.criterion_status<>'not_applicable')
from public.evaluate_funding_eligibility_v22(target_artist,target_project,target_organization) e
group by e.funding_program_id,e.provider_name,e.program_name;
$$;
grant execute on function public.funding_eligibility_summary_v22(uuid,uuid,uuid) to authenticated;

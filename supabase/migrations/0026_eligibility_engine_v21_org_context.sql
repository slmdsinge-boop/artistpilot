-- Eligibility engine V2.1: evaluate project + selected organization facts together.
-- Keeps missing facts unknown and only consumes verified criteria.
create or replace function public.evaluate_funding_eligibility_v21(
 target_artist uuid,target_project uuid,target_organization uuid default null
)
returns table(
 funding_program_id uuid,provider_name text,program_name text,criterion_key text,
 criterion_subject_type text,criterion_status text,actual_value jsonb,expected_value jsonb,
 operator text,source_text text,source_url text
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
 select c.*,f.value actual_value from criteria c
 left join facts f on f.fact_key=c.criterion_key and f.subject_type=c.subject_type
)
select funding_program_id,provider_name,program_name,criterion_key,subject_type,
case
 when actual_value is null then 'missing_information'
 when operator='not_null' then 'satisfied'
 when operator='eq' and actual_value=expected_value then 'satisfied'
 when operator='neq' and actual_value<>expected_value then 'satisfied'
 when operator='gte' and jsonb_typeof(actual_value)='number' and jsonb_typeof(expected_value)='number' and (actual_value#>>'{}')::numeric >= (expected_value#>>'{}')::numeric then 'satisfied'
 when operator='lte' and jsonb_typeof(actual_value)='number' and jsonb_typeof(expected_value)='number' and (actual_value#>>'{}')::numeric <= (expected_value#>>'{}')::numeric then 'satisfied'
 when operator='gt' and jsonb_typeof(actual_value)='number' and jsonb_typeof(expected_value)='number' and (actual_value#>>'{}')::numeric > (expected_value#>>'{}')::numeric then 'satisfied'
 when operator='lt' and jsonb_typeof(actual_value)='number' and jsonb_typeof(expected_value)='number' and (actual_value#>>'{}')::numeric < (expected_value#>>'{}')::numeric then 'satisfied'
 when operator='in' and jsonb_typeof(expected_value)='array' and expected_value @> jsonb_build_array(actual_value) then 'satisfied'
 else 'criterion_not_met' end,
actual_value,expected_value,operator,source_text,source_url from matched;
$$;
grant execute on function public.evaluate_funding_eligibility_v21(uuid,uuid,uuid) to authenticated;

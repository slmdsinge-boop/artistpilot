-- Deterministic eligibility engine V2.
-- Evaluates ONLY verified atomic criteria against explicit entity_facts.
-- Missing fact = missing_information, never false.
create or replace function public.evaluate_funding_eligibility(
  target_artist uuid,
  target_subject_type text,
  target_subject_id uuid
)
returns table(
  funding_program_id uuid,
  provider_name text,
  program_name text,
  criterion_key text,
  criterion_subject_type text,
  criterion_status text,
  actual_value jsonb,
  expected_value jsonb,
  operator text,
  source_text text,
  source_url text
)
language sql stable security invoker
set search_path=public
as $$
with programs as (
 select fp.*
 from public.funding_programs fp
 where fp.verification_status='verified'
), criteria as (
 select fc.*,p.provider_name,p.name program_name
 from public.funding_criteria fc join programs p on p.id=fc.funding_program_id
 where fc.verification_status='verified'
), facts as (
 select ef.*
 from public.entity_facts ef
 where ef.artist_id=target_artist
   and (
    (ef.subject_type=target_subject_type and ef.subject_id=target_subject_id)
    or ef.subject_type='artist'
   )
), matched as (
 select c.*,f.value actual_value
 from criteria c
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
 else 'criterion_not_met'
end criterion_status,
actual_value,expected_value,operator,source_text,source_url
from matched;
$$;

create or replace function public.funding_eligibility_summary(
 target_artist uuid,target_subject_type text,target_subject_id uuid
)
returns table(funding_program_id uuid,provider_name text,program_name text,eligibility_status text,satisfied_count bigint,missing_count bigint,not_met_count bigint,total_count bigint)
language sql stable security invoker set search_path=public as $$
select e.funding_program_id,e.provider_name,e.program_name,
case
 when count(*) filter(where e.criterion_status='criterion_not_met')>0 then 'criterion_not_met'
 when count(*) filter(where e.criterion_status='missing_information')>0 then 'missing_information'
 else 'potentially_compatible'
end,
count(*) filter(where e.criterion_status='satisfied'),
count(*) filter(where e.criterion_status='missing_information'),
count(*) filter(where e.criterion_status='criterion_not_met'),
count(*)
from public.evaluate_funding_eligibility(target_artist,target_subject_type,target_subject_id) e
group by e.funding_program_id,e.provider_name,e.program_name;
$$;

grant execute on function public.evaluate_funding_eligibility(uuid,text,uuid) to authenticated;
grant execute on function public.funding_eligibility_summary(uuid,text,uuid) to authenticated;

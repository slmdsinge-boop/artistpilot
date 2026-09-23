-- Eligibility V2.3 must use the project's persisted carrier organization.
-- Keep the existing RPC signature for compatibility, but reject a caller-supplied
-- organization that differs from projects.organization_id. Null is valid only when
-- the project itself has no carrier organization.

create or replace function public.evaluate_funding_eligibility_v23(
 target_artist uuid,target_project uuid,target_organization uuid default null
)
returns table(
 funding_program_id uuid,provider_name text,program_name text,criterion_key text,
 criterion_subject_type text,criterion_status text,actual_value jsonb,expected_value jsonb,
 operator text,source_text text,source_url text,blocking boolean,criterion_kind text
)
language sql stable security invoker set search_path=public as $$
with target as (
 select p.id,p.project_type,p.organization_id
 from public.projects p
 where p.id=target_project
   and p.artist_id=target_artist
   and target_organization is not distinct from p.organization_id
), criteria as (
 select fc.*,fp.provider_name,fp.name program_name
 from public.funding_criteria fc
 join public.funding_programs fp on fp.id=fc.funding_program_id
 cross join target t
 where fc.verification_status='verified' and fp.verification_status='verified'
 and (
   fp.project_types is null
   or cardinality(fp.project_types)=0
   or t.project_type = any(fp.project_types)
 )
), facts as (
 select ef.*
 from public.entity_facts ef
 cross join target t
 where ef.artist_id=target_artist and (
  (ef.subject_type='project' and ef.subject_id=t.id)
  or (t.organization_id is not null and ef.subject_type='organization' and ef.subject_id=t.organization_id)
  or (ef.subject_type='artist' and ef.subject_id=target_artist)
 )
), matched as (
 select c.*,f.value actual_value,cf.value condition_actual
 from criteria c
 left join facts f on f.fact_key=c.criterion_key and f.subject_type=c.subject_type
 left join facts cf on c.applies_when is not null
   and cf.fact_key=c.applies_when->>'fact_key'
   and cf.subject_type=c.applies_when->>'subject_type'
)
select funding_program_id,provider_name,program_name,criterion_key,subject_type,
 case
  when applies_when is not null and condition_actual is null then 'pending_context'
  when applies_when is not null and coalesce(applies_when->>'operator','eq')='eq' and condition_actual is distinct from (applies_when->'value') then 'not_applicable'
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
 actual_value,expected_value,operator,source_text,source_url,blocking,criterion_kind
from matched;
$$;

grant execute on function public.evaluate_funding_eligibility_v23(uuid,uuid,uuid) to authenticated;

comment on function public.evaluate_funding_eligibility_v23(uuid,uuid,uuid) is
'Evaluates verified eligibility criteria for a project using only its persisted carrier organization; a mismatched caller-supplied organization yields no evaluation rows.';

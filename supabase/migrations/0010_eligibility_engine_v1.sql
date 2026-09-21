-- First deterministic eligibility checks for verified programs.
-- Unknown facts stay missing; they are never treated as false.
create or replace function public.project_funding_matches(target_artist uuid)
returns table (
 project_id uuid, project_name text, project_type text, funding_program_id uuid,
 provider_name text, program_name text, official_url text, verification_status text,
 match_status text, reason text
)
language sql security invoker set search_path=public as $$
with base as (
 select p.*, f.id fid, f.provider_name fp, f.name fn, f.official_url fu, f.verification_status fv, f.project_types,
        o.cnm_affiliated,o.adami_affiliated,o.spedidam_affiliated,o.sppf_affiliated,
        o.spectacle_licence,o.employs_artists,o.phonogram_producer,o.owns_masters
 from projects p cross join funding_programs f
 left join organizations o on o.id=p.organization_id and o.artist_id=p.artist_id
 where p.artist_id=target_artist and f.verification_status<>'archived'
), assessed as (
 select *,
 case
  when fv<>'verified' then 'to_verify'
  when cardinality(project_types)=0 then 'needs_info'
  when not(project_type=any(project_types)) then 'not_match'
  when organization_id is null then 'needs_info'
  when fp='CNM' and cnm_affiliated is false then 'criterion_not_met'
  when fp='CNM' and cnm_affiliated is null then 'needs_info'
  when fp='ADAMI' and adami_affiliated is false then 'criterion_not_met'
  when fp='ADAMI' and adami_affiliated is null then 'needs_info'
  when fp='SPEDIDAM' and spedidam_affiliated is false then 'criterion_not_met'
  when fp='SPEDIDAM' and spedidam_affiliated is null then 'needs_info'
  when fp='SPPF' and sppf_affiliated is false then 'criterion_not_met'
  when fp='SPPF' and sppf_affiliated is null then 'needs_info'
  when (lower(fn) like '%spectacle%' or lower(fn) like '%diffusion%') and spectacle_licence is null then 'needs_info'
  when (lower(fn) like '%spectacle%' or lower(fn) like '%diffusion%') and spectacle_licence is false then 'criterion_not_met'
  when (lower(fn) like '%spectacle%' or lower(fn) like '%production phonographique%') and employs_artists is null then 'needs_info'
  when lower(fn) like '%production phonographique%' and phonogram_producer is null then 'needs_info'
  when lower(fn) like '%production phonographique%' and owns_masters is null then 'needs_info'
  else 'potential_match' end ms
 from base
)
select id,name,project_type,fid,fp,fn,fu,fv,ms,
 case ms
  when 'potential_match' then 'Les critères structurés connus correspondent. Les critères non encore structurés restent à vérifier sur la source officielle.'
  when 'needs_info' then 'Des informations administratives ou de projet manquent pour poursuivre la vérification.'
  when 'criterion_not_met' then 'Au moins un critère structuré connu n’est pas rempli.'
  when 'not_match' then 'Le type de projet ne correspond pas aux types enregistrés pour ce dispositif.'
  else 'Le dispositif doit encore être vérifié.'
 end
from assessed;
$$;
grant execute on function public.project_funding_matches(uuid) to authenticated;

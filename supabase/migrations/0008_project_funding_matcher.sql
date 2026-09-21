-- Deterministic first-pass matching. This is compatibility, not a final eligibility decision.
create or replace function public.project_funding_matches(target_artist uuid)
returns table (
  project_id uuid,
  project_name text,
  project_type text,
  funding_program_id uuid,
  provider_name text,
  program_name text,
  official_url text,
  verification_status text,
  match_status text,
  reason text
)
language sql
security invoker
set search_path = public
as $$
  select
    p.id, p.name, p.project_type,
    f.id, f.provider_name, f.name, f.official_url, f.verification_status,
    case
      when f.verification_status <> 'verified' then 'to_verify'
      when cardinality(f.project_types)=0 then 'to_check'
      when p.project_type = any(f.project_types) then 'potential_match'
      else 'not_match'
    end,
    case
      when f.verification_status <> 'verified' then 'Le dispositif doit encore être vérifié.'
      when cardinality(f.project_types)=0 then 'Le type de projet ne suffit pas pour conclure.'
      when p.project_type = any(f.project_types) then 'Le type de projet correspond. Les autres critères restent à contrôler.'
      else 'Le type de projet ne correspond pas aux types enregistrés pour ce dispositif.'
    end
  from public.projects p
  cross join public.funding_programs f
  where p.artist_id = target_artist
    and f.verification_status <> 'archived';
$$;
grant execute on function public.project_funding_matches(uuid) to authenticated;

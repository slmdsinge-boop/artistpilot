-- Funding-program applicability must use the same canonical project-type vocabulary
-- as projects. Unknown catalogue values could otherwise silently classify a verified
-- program as not applicable instead of surfacing verification work.

do $$
begin
  if exists (
    select 1
    from public.funding_programs fp,
         unnest(fp.project_types) as project_type
    where project_type not in (
      'album','ep','single','clip','tournee','spectacle','festival','residence','autre'
    )
  ) then
    raise exception 'funding program project type preflight failed: review non-canonical project_types';
  end if;
end $$;

alter table public.funding_programs
  drop constraint if exists funding_programs_project_types_canonical;

alter table public.funding_programs
  add constraint funding_programs_project_types_canonical
  check (
    project_types <@ array[
      'album','ep','single','clip','tournee','spectacle','festival','residence','autre'
    ]::text[]
  );

comment on constraint funding_programs_project_types_canonical on public.funding_programs is
'Program applicability uses only the canonical ArtistPilot project-type vocabulary; empty arrays remain broad applicability and are handled by readiness.';

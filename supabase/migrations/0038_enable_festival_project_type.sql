-- Festival is now a canonical project type in ArtistPilot.
-- Restore the SPEDIDAM festival program to verified applicability without changing its criteria or source dates.
update public.funding_programs
set verification_status='verified',
    eligibility_notes=replace(coalesce(eligibility_notes,''),' Applicabilité projet à formaliser : le type festival n’existe pas encore dans le formulaire projet.',''),
    updated_at=now()
where provider_name='SPEDIDAM'
  and name='Aide aux festivals'
  and project_types=array['festival'];

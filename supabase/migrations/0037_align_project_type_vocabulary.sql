-- Align program applicability with the canonical project-type vocabulary used by the app.
-- Do not broaden semantic scope: only map existing verified program meanings to existing UI types.

update public.funding_programs
set project_types=array['clip'], updated_at=now()
where provider_name='SPEDIDAM' and name='Aide à la promotion par l’image'
  and project_types=array['video_promotionnelle'];

-- Festival is not yet a canonical project type in the UI. Keep it visible for verification,
-- but never silently classify an unrelated project as a festival.
update public.funding_programs
set verification_status='to_verify',
    eligibility_notes=coalesce(eligibility_notes,'') || ' Applicabilité projet à formaliser : le type festival n’existe pas encore dans le formulaire projet.',
    updated_at=now()
where provider_name='SPEDIDAM' and name='Aide aux festivals'
  and project_types=array['festival'];

-- A soundtrack can belong to a spectacle in the current model; retain spectacle only until
-- a dedicated soundtrack project type is introduced.
update public.funding_programs
set project_types=array['spectacle'], updated_at=now()
where provider_name='SPEDIDAM'
  and name='Aide à la création d’une bande originale pour spectacle dramatique ou chorégraphique'
  and project_types @> array['bande_originale'];

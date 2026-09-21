-- Enforce funding-application uniqueness at the database layer.
-- A project can track a given program only once.
create unique index if not exists funding_applications_unique_project_program
on public.funding_applications(artist_id,funding_program_id,project_id)
where project_id is not null;

-- Without a project, uniqueness is scoped to the selected carrier organization.
create unique index if not exists funding_applications_unique_unassigned_org_program
on public.funding_applications(artist_id,funding_program_id,organization_id)
where project_id is null and organization_id is not null;

-- Also protect the fully unassigned case.
create unique index if not exists funding_applications_unique_unassigned_program
on public.funding_applications(artist_id,funding_program_id)
where project_id is null and organization_id is null;

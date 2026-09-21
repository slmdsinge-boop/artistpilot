-- Funding workflow statuses describe dossier progress, not deterministic eligibility.
-- Keep legacy 'eligible' for compatibility, but new UI should no longer write it.

comment on column public.funding_applications.status is
'Workflow status of the funding dossier. Eligibility is computed separately by the deterministic eligibility engine and must not be inferred from this field.';

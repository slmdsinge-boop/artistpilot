-- Conditional criteria foundation.
-- A criterion with applies_when is evaluated only when the referenced fact matches.
-- If that condition is unknown, the criterion is reported as not_applicable_pending_context,
-- never as failed.
alter table public.funding_criteria add column if not exists applies_when jsonb;
alter table public.funding_criteria add column if not exists criterion_kind text not null default 'eligibility'
 check (criterion_kind in ('eligibility','calculation','document','manual'));
comment on column public.funding_criteria.applies_when is 'Optional condition: {"fact_key":"...","subject_type":"project","operator":"eq","value":...}. Null means always applicable.';
comment on column public.funding_criteria.criterion_kind is 'Separates blocking eligibility from calculation/document/manual rules.';

-- Known SPEDIDAM alternative regimes: do not treat both branches as simultaneous blockers.
update public.funding_criteria
set applies_when='{"fact_key":"large_ensemble_8_artists","subject_type":"project","operator":"eq","value":false}'::jsonb
where criterion_key='aid_share_standard' and verification_status='verified';

update public.funding_criteria
set applies_when='{"fact_key":"large_ensemble_8_artists","subject_type":"project","operator":"eq","value":true}'::jsonb
where criterion_key='aid_share_large_ensemble' and verification_status='verified';

-- Geographic caps and DROM-specific share require explicit contextual facts before evaluation.
update public.funding_criteria set criterion_kind='calculation', blocking=false
where criterion_key in ('europe_cap_per_artist','world_cap_per_artist','drom_metropole_aid_share','performance_fee_calculation_cap','music_commission_cap','composer_performer_combined_cap')
and verification_status='verified';

-- Calculation ceilings inform the dossier but must not independently reject a project.
update public.funding_criteria set criterion_kind='calculation', blocking=false
where criterion_key in ('aid_amount','standard_aid_share','aid_share','sppf_request_share','producer_own_contribution_share')
and verification_status='verified';

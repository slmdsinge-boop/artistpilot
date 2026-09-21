-- Correct SPEDIDAM large-ensemble context: it is an alternative regime, not a universal eligibility requirement.
update public.funding_criteria fc
set required=false,
    blocking=false,
    criterion_kind='manual',
    updated_at=now()
from public.funding_programs fp
where fc.funding_program_id=fp.id
  and fp.provider_name='SPEDIDAM'
  and fp.name='Aide spectacle musical'
  and fc.criterion_key='large_ensemble_8_artists';

-- The fact is still useful to select the applicable funding-share branch, but must never reject standard ensembles.
comment on column public.funding_criteria.applies_when is 'Conditional applicability. Context facts may select a rule branch without themselves being universal eligibility requirements.';

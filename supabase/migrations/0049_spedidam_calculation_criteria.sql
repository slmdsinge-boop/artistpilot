update public.funding_criteria fc set criterion_kind='calculation',blocking=false,updated_at=now()
from public.funding_programs fp where fc.funding_program_id=fp.id and fp.provider_name='SPEDIDAM' and fp.name='Aide spectacle musical'
and fc.criterion_key in('aid_share_standard','aid_share_large_ensemble');
